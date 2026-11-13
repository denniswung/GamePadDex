import io
root = r"E:\Dennis\GamePadDex复刻\project"

# ---------- helper: J <display> -> click the caption's fullscreen button ----------
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
if "caption_fullscreen_click" not in c:
    fn = r"""
// Finds the foreground app window on the given display, computes the position of
// the DeX caption "fullscreen" button (2nd from the right) and clicks it through
// the injector.
static void caption_fullscreen_click(int displayId) {
    FILE *p = popen("dumpsys window windows 2>/dev/null", "r");
    if (!p) { out("CAPTION no-dumpsys"); return; }
    char line[512];
    int right = -1, top = -1;
    while (fgets(line, sizeof(line), p)) {
        int a, b, c2, d;
        if (sscanf(line, " %*[^=]=[%d,%d][%d,%d]", &a, &b, &c2, &d) == 0) {
            // the frame line looks like: Frames: containing=[x1,y1][x2,y2] parent=...
            char *f = strstr(line, "containing=[");
            if (f && sscanf(f, "containing=[%d,%d][%d,%d]", &a, &b, &c2, &d) == 4) {
                if (c2 > 0 && d > 0) { right = c2; top = b; break; }
            }
        }
    }
    pclose(p);
    if (right <= 0 || top < 0) { out("CAPTION not-found"); return; }
    // icon centres measured on this device: close = right-18, fullscreen = right-84
    int x = right - 84;
    int y = top + 30;
    out("CAPTION click %d,%d (window right=%d top=%d)", x, y, right, top);
    injector_key(displayId, 0);   // keep the pipe warm (ignored key 0)
    if (g_inject_fd >= 0) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "m %d %d %d 1\n", displayId, x, y);
        if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
    }
}

"""
    c = c.replace("static void injector_combo(", fn + "static void injector_combo(", 1)
    c = c.replace("        case 'F': {", """        case 'J': {
            int jd = 0;
            if (sscanf(line, "%d", &jd) == 1 && jd > 0) caption_fullscreen_click(jd);
            break;
        }
        case 'F': {""", 1)
    # caption_fullscreen_click uses injector_key which is declared later; forward declare
    c = c.replace("static void caption_fullscreen_click(int displayId) {",
                  "static void injector_key(int displayId, int androidKeyCode);\n\nstatic void caption_fullscreen_click(int displayId) {", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("helper J added")

# ---------- RootInput ----------
rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
if "fun fullscreenClick" not in r:
    r = r.replace("    /** relaunch a component in fullscreen windowing mode on a display (root) */",
"""    /** click the DeX caption fullscreen button (root, coordinates resolved on the fly) */
    fun fullscreenClick(displayId: Int): Boolean {
        if (!isRunning) return false
        send("J $displayId")
        return helperReady
    }

    /** relaunch a component in fullscreen windowing mode on a display (root) */""", 1)
    io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")

# ---------- service: use it first ----------
sp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
s = s.replace('''            "dex_fullscreen" -> {
                val ok = dexFullscreenClick()''',
'''            "dex_fullscreen" -> {
                val dispNow = targetDisplayId()
                val rootOk = try { root?.fullscreenClick(dispNow) ?: false } catch (t: Throwable) { false }
                Log.i(TAG, "dex_fullscreen caption click -> " + rootOk + " display " + dispNow)
                val ok = rootOk || dexFullscreenClick()''', 1)
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service ok")
