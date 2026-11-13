import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(p, encoding="utf-8").read()

# ---- globals + helpers before scan_new_devices ----
anchor = "static void scan_new_devices(void) {"
assert anchor in s
helpers = r'''/* ---- connect-to-wake ---- */
static int g_wake_on_connect = 1;
static time_t g_last_wake_at = 0;
static int g_scan_primed = 0;
static int g_scan_count = 0;

/* 1 = Awake, 0 = not awake, -1 = unknown */
static int screen_awake(void) {
    FILE *p = popen("dumpsys power 2>/dev/null | grep -m1 mWakefulness=", "r");
    if (!p) return -1;
    char b[128] = {0};
    int awake = -1;
    if (fgets(b, sizeof(b), p)) awake = strstr(b, "Awake") ? 1 : 0;
    pclose(p);
    return awake;
}

/* called when a *new* gamepad node appears (not the initial enumeration) */
static void maybe_wake_on_connect(const char *path, const char *name) {
    if (!g_scan_primed || !g_wake_on_connect) return;
    time_t now = time(NULL);
    if (now - g_last_wake_at < 3) return;           /* debounce */
    int st = screen_awake();
    if (st == 1) {
        out("WAKE_CONNECT skip awake %s", name);
        return;
    }
    g_last_wake_at = now;
    system("input keyevent 224");                    /* KEYCODE_WAKEUP */
    out("WAKE_CONNECT %s %s (was %d)", path, name, st);
}

static void scan_new_devices(void) {'''
s = s.replace(anchor, helpers, 1)

# ---- trigger after a successful new device ----
old = '''        out("DEV %d %s", d->id, d->name);
        if (d->grabbed) out("GRABBED %d %s", d->id, d->name);
        g_ndev++;'''
new = '''        out("DEV %d %s", d->id, d->name);
        if (d->grabbed) out("GRABBED %d %s", d->id, d->name);
        g_ndev++;
        maybe_wake_on_connect(d->path, d->name);'''
assert old in s
s = s.replace(old, new, 1)

# ---- mark enumeration as primed after the second scan ----
old2 = '''            scan_new_devices();
            ping_client();'''
new2 = '''            scan_new_devices();
            if (++g_scan_count >= 2) g_scan_primed = 1;
            ping_client();'''
assert old2 in s
s = s.replace(old2, new2, 1)

# ---- selftest + wake switch + wheel anchor commands ----
old3 = "        case 'p': {"
new3 = r'''        case '?': {
            out("SELFTEST ndev=%d grab=%d wake_on=%d wake=%d",
                g_ndev, g_grab_mode, g_wake_on_connect, screen_awake());
            break;
        }
        case 'J': {
            int on = 1;
            sscanf(line, "%d", &on);
            g_wake_on_connect = on ? 1 : 0;
            out("WAKE_ON %d", g_wake_on_connect);
            break;
        }
        case 'T': {
            int disp = 0, mx = 0, my = 0;
            if (sscanf(line, "%d %d %d", &disp, &mx, &my) >= 1) {
                if (fork() == 0) { cmd_anchor_wheel(disp, mx, my); _exit(0); }
            }
            break;
        }
        case 'p': {'''
assert old3 in s
s = s.replace(old3, new3, 1)

# ---- cmd_anchor_wheel implementation before cmd_swipe ----
old4 = "static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {"
impl = r'''/* ensure the pointer is inside the focused task, then the caller sends wheel */
static void cmd_anchor_wheel(int display, int maxX, int maxY) {
    (void)display;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");
    if (t) {
        char tl[2048];
        int l0 = 0, t0 = 0, r0 = 0, b0 = 0, have = 0, since = 999;
        while (fgets(tl, sizeof(tl), t)) {
            since++;
            char *mb = strstr(tl, "mBounds=Rect(");
            if (mb) {
                int x1 = 0, y1 = 0, x2 = 0, y2 = 0;
                if (sscanf(mb + strlen("mBounds=Rect("), "%d, %d - %d, %d", &x1, &y1, &x2, &y2) == 4) {
                    l0 = x1; t0 = y1; r0 = x2; b0 = y2; have = 1; since = 0;
                }
            }
            if (strstr(tl, "topResumedActivity=ActivityRecord{")) {
                if (have && since <= 12 && r0 > l0 && b0 > t0 &&
                    r0 <= maxX + 200 && b0 <= maxY + 200) {
                    bx1 = l0; by1 = t0; bx2 = r0; by2 = b0;
                }
                break;
            }
        }
        pclose(t);
    }
    int cx = -1, cy = -1;
    read_pointer(&cx, &cy);
    int inside = cx > bx1 + 10 && cx < bx2 - 10 && cy > by1 + 10 && cy < by2 - 10;
    if (!inside) {
        int tx = (bx1 + bx2) / 2, ty = (by1 + by2) / 2;
        int dx = tx - cx, dy = ty - cy;
        if (cx < 0) { dx = tx; dy = ty; }
        cmd_mouse_move(dx / 3.25, dy / 3.25);
        usleep(80 * 1000);
        out("ANCHOR move %d,%d -> task %d,%d-%d,%d", dx, dy, bx1, by1, bx2, by2);
    } else {
        out("ANCHOR inside task %d,%d-%d,%d", bx1, by1, bx2, by2);
    }
}

static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct) {'''
assert old4 in s
s = s.replace(old4, impl, 1)

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("helper v2 patched")
