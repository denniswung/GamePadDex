import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()

# 1) 全局绝对指针设备
s = s.replace("static int g_pad = -1;",
              "static int g_pad = -1;\n/* 绝对指针设备：只用来「一次性把指针放到指定坐标」（相对鼠标有加速度，算不准） */\nstatic int g_abs_ptr = -1;", 1)

# 2) 构造绝对指针
anchor = "static int make_keyboard(void) {"
if anchor not in s:
    print("MISS kbd"); sys.exit(1)
maker = '''/* 绝对指针（cursor input）：系统把它当鼠标，但坐标是绝对的，
 * 因此「居中」只需一条 EV_ABS，不需要猜像素增益。 */
static int make_abs_pointer(void) {
    int fd = uinput_open();
    if (fd < 0) return -1;
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
    ioctl(fd, UI_SET_KEYBIT, BTN_RIGHT);
    ioctl(fd, UI_SET_KEYBIT, BTN_MIDDLE);
#ifdef UI_SET_PROPBIT
    ioctl(fd, UI_SET_PROPBIT, INPUT_PROP_POINTER);
#endif
    ioctl(fd, UI_SET_ABSBIT, ABS_X);
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);
    struct uinput_abs_setup as;
    memset(&as, 0, sizeof(as));
    as.code = ABS_X;
    as.absinfo.minimum = 0;
    as.absinfo.maximum = 32767;
    ioctl(fd, UI_ABS_SETUP, &as);
    memset(&as, 0, sizeof(as));
    as.code = ABS_Y;
    as.absinfo.minimum = 0;
    as.absinfo.maximum = 32767;
    ioctl(fd, UI_ABS_SETUP, &as);

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x567a;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Absolute Pointer");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { close(fd); return -1; }
    return fd;
}

'''
s = s.replace(anchor, maker + anchor, 1)

# 3) 居中：优先绝对指针，一条事件到位
old_center = s[s.index("/* move the pointer to the centre of the display"):s.index("static void cmd_wheel(")]
new_center = '''/* move the pointer to the centre of the display: O <maxX> <maxY> [park] [rot] */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int tx = maxX / 2, ty = maxY / 2;
    if (g_abs_ptr >= 0) {
        /* 一次性居中：绝对坐标，没有「先回角再跳」的中间态，也不受指针加速度影响 */
        int ax = (int)((long)tx * 32767 / (maxX > 0 ? maxX : 1));
        int ay = (int)((long)ty * 32767 / (maxY > 0 ? maxY : 1));
        ev_emit(g_abs_ptr, EV_ABS, ABS_X, ax);
        ev_emit(g_abs_ptr, EV_ABS, ABS_Y, ay);
        ev_syn(g_abs_ptr);
        out("CENTER(abs %d,%d) -> %d,%d", ax, ay, tx, ty);
        return;
    }
    /* 兜底：没有绝对设备时先归零再按实测增益跳过去 */
    cmd_mouse_move(-30000.0, -30000.0);
    usleep(60 * 1000);
    cmd_mouse_move(tx / 2.16, ty / 2.16);
    out("CENTER(linear 2.16 fallback) -> target %d,%d", tx, ty);
}

'''
s = s.replace(old_center, new_center, 1)

# 4) 启动时创建 + j 恢复时重建
s = s.replace("    g_pad = make_gamepad();", "    g_pad = make_gamepad();\n    g_abs_ptr = make_abs_pointer();", 1)
s = s.replace("""            if (g_mouse < 0) {
                g_mouse = make_mouse();
                usleep(120 * 1000);
                out("POINTER on");
            }""",
"""            if (g_mouse < 0) {
                g_mouse = make_mouse();
                usleep(120 * 1000);
                out("POINTER on");
            }
            if (g_abs_ptr < 0) g_abs_ptr = make_abs_pointer();""", 1)
s = s.replace("""            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }""",
"""            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }
            if (g_abs_ptr >= 0) {
                ioctl(g_abs_ptr, UI_DEV_DESTROY);
                close(g_abs_ptr);
                g_abs_ptr = -1;
            }""", 1)

io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
