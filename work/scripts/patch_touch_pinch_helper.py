import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# ---------- 1) 全局状态 ----------
if "g_touch_panel" not in s:
    s = s.replace("static char g_top_pkg[192];",
"""static char g_top_pkg[192];
/* 虚拟触摸屏：给"点击=触摸"和"双指缩放"用（真实触摸事件，带多点协议 B） */
static int g_touch_panel = -1;
static int g_touch_w = 1600, g_touch_h = 2560;
static int g_touch_slot0 = -1, g_touch_slot1 = -1;
static int g_pinch_dir = 0;          /* +1 放大 / -1 缩小 / 0 停止 */
static int g_pinch_d = 60;           /* 两指参考距离 */
static int g_pinch_x = 0, g_pinch_y = 0;   /* 缩放基准点（光标位置） */
static long long g_pinch_last_us = 0;""", 1)

# ---------- 2) 触摸屏设备 ----------
anchor = "static int make_keyboard(void) {"
if "make_touchscreen" not in s:
    maker = '''/* 虚拟触摸屏：Android 用多点协议 B（SLOT + TRACKING_ID + POSITION）。
 * INPUT_PROP_DIRECT 让系统把它当真正的触摸板而不是鼠标。 */
static int make_touchscreen(void) {
    int fd = uinput_open();
    if (fd < 0) return -1;
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_TOUCH);
#ifdef UI_SET_PROPBIT
    ioctl(fd, UI_SET_PROPBIT, INPUT_PROP_DIRECT);
#endif
    int axes[] = { ABS_X, ABS_Y, ABS_MT_SLOT, ABS_MT_TRACKING_ID,
                   ABS_MT_POSITION_X, ABS_MT_POSITION_Y };
    for (size_t i = 0; i < sizeof(axes) / sizeof(axes[0]); i++) ioctl(fd, UI_SET_ABSBIT, axes[i]);

    struct uinput_abs_setup as;
    for (size_t i = 0; i < sizeof(axes) / sizeof(axes[0]); i++) {
        memset(&as, 0, sizeof(as));
        as.code = axes[i];
        if (axes[i] == ABS_MT_SLOT) { as.absinfo.minimum = 0; as.absinfo.maximum = 9; }
        else if (axes[i] == ABS_MT_TRACKING_ID) { as.absinfo.minimum = -1; as.absinfo.maximum = 65535; }
        else { as.absinfo.minimum = 0; as.absinfo.maximum = 32767; }
        ioctl(fd, UI_ABS_SETUP, &as);
    }

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x567b;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Touch Panel");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { close(fd); return -1; }
    return fd;
}

/* 把一个屏幕像素坐标换算成触摸设备的 0..32767 坐标 */
static int touch_axis(int v, int max) {
    if (max <= 0) max = 1;
    if (v < 0) v = 0;
    if (v > max) v = max;
    return (int)((long long)v * 32767 / max);
}

static void touch_frame(int slot, int tid, int x, int y) {
    if (g_touch_panel < 0) return;
    ev_emit(g_touch_panel, EV_ABS, ABS_MT_SLOT, slot);
    ev_emit(g_touch_panel, EV_ABS, ABS_MT_TRACKING_ID, tid);
    if (tid >= 0) {
        ev_emit(g_touch_panel, EV_ABS, ABS_MT_POSITION_X, touch_axis(x, g_touch_w));
        ev_emit(g_touch_panel, EV_ABS, ABS_MT_POSITION_Y, touch_axis(y, g_touch_h));
    }
    ev_syn(g_touch_panel);
}

/* 单指按下 / 抬起（点击、长按） */
static void touch_single(int x, int y, int down) {
    if (g_touch_panel < 0) { g_touch_panel = make_touchscreen(); usleep(120 * 1000); }
    if (g_touch_panel < 0) { out("ERR touch device"); return; }
    if (down) {
        if (g_touch_slot0 < 0) { g_touch_slot0 = 1; ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 1); }
        touch_frame(0, g_touch_slot0, x, y);
        out("TOUCH down %d,%d", x, y);
    } else {
        if (g_touch_slot0 >= 0) {
            touch_frame(0, -1, 0, 0);
            ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 0);
            ev_syn(g_touch_panel);
            g_touch_slot0 = -1;
            out("TOUCH up");
        }
    }
}

/* 双指缩放：由主循环按 8~16ms 节奏推动，按住期间连续生效 */
static void pinch_stop(void) {
    if (g_pinch_dir == 0) return;
    g_pinch_dir = 0;
    if (g_touch_panel >= 0) {
        if (g_touch_slot1 >= 0) touch_frame(1, -1, 0, 0);
        if (g_touch_slot0 >= 0) touch_frame(0, -1, 0, 0);
        ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 0);
        ev_syn(g_touch_panel);
    }
    g_touch_slot0 = g_touch_slot1 = -1;
    out("PINCH stop");
}

static void pinch_start(int dir, int x, int y) {
    if (g_touch_panel < 0) { g_touch_panel = make_touchscreen(); usleep(120 * 1000); }
    if (g_touch_panel < 0) { out("ERR touch device"); return; }
    pinch_stop();
    g_pinch_dir = dir > 0 ? 1 : -1;
    g_pinch_x = x;
    g_pinch_y = y;
    g_pinch_d = 80;
    g_touch_slot0 = 11;
    g_touch_slot1 = 12;
    g_pinch_last_us = 0;
    ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 1);
    touch_frame(0, g_touch_slot0, x - g_pinch_d, y);
    touch_frame(1, g_touch_slot1, x + g_pinch_d, y);
    out("PINCH start dir=%d at %d,%d", dir, x, y);
}

static void pinch_tick(void) {
    if (g_pinch_dir == 0 || g_touch_panel < 0) return;
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    long long now = (long long)ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
    if (now - g_pinch_last_us < 14000) return;   /* ~70 fps */
    g_pinch_last_us = now;
    g_pinch_d += g_pinch_dir * 9;
    int limit = g_touch_h / 3;
    if (limit < 120) limit = 120;
    if (g_pinch_d < 24) g_pinch_d = 24;
    if (g_pinch_d > limit) g_pinch_d = limit;
    touch_frame(0, g_touch_slot0, g_pinch_x - g_pinch_d, g_pinch_y);
    touch_frame(1, g_touch_slot1, g_pinch_x + g_pinch_d, g_pinch_y);
}

'''
    s = s.replace(anchor, maker + anchor, 1)

# ---------- 3) 命令：j 设置触摸尺寸 / k 单指 / l 双指缩放 ----------
if "case 'j': {" not in s:
    idx = s.index("        case 'g': {")
    cmds = """        case 'j': {
            /* j <w> <h> : 触摸面尺寸（用于像素坐标换算） */
            int tw = 0, th = 0;
            if (sscanf(line, "%d %d", &tw, &th) == 2 && tw > 0 && th > 0) {
                g_touch_w = tw; g_touch_h = th;
                out("TOUCH_SIZE %d %d", g_touch_w, g_touch_h);
            }
            break;
        }
        case 'k': {
            /* k <x> <y> <down> : 单指触摸（点击 / 长按） */
            int tx = 0, ty = 0, dn = 0;
            if (sscanf(line, "%d %d %d", &tx, &ty, &dn) == 3) touch_single(tx, ty, dn);
            break;
        }
        case 'l': {
            /* l <dir> <x> <y> : 双指缩放，dir 0=停止，1=放大，-1=缩小 */
            int dir = 0, px = 0, py = 0;
            if (sscanf(line, "%d %d %d", &dir, &px, &py) == 3) {
                if (dir == 0) pinch_stop();
                else pinch_start(dir, px, py);
            }
            break;
        }
"""
    s = s[:idx] + cmds + s[idx:]

# ---------- 4) 主循环：pinch 用短超时 ----------
old_poll = """        int rc = poll(pfd, n, 400);
        reap_children();"""
new_poll = """        int rc = poll(pfd, n, g_pinch_dir != 0 ? 8 : 400);
        reap_children();
        pinch_tick();"""
if old_poll not in s:
    print("MISS poll"); sys.exit(1)
s = s.replace(old_poll, new_poll, 1)

# rc == 0 时也要继续 pinch
s = s.replace("        if (rc == 0) continue;", "        if (rc == 0) { pinch_tick(); continue; }", 1)

# ---------- 5) 清理旧的临时命令 q/k（k 已被复用） ----------
if "ABS_MOVE" in s:
    a = s.index("        case 'q': {")
    b = s.index("        case 'g': {")
    s = s[:a] + s[b:]
    s = s.replace("""        case 'k': {
            /* 试验：直接从本域执行 am force-stop */""", """        case 'Z': {
            /* 试验：直接从本域执行 am force-stop */""", 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("helper patched")
