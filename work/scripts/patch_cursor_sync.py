import io, os
root = r"E:\Dennis\GamePadDex复刻\project"

# ---------- helper: report the real cursor position ----------
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
if "static void query_cursor" not in c:
    q = r"""
// Reads the system pointer position from SurfaceFlinger's cursor sprite layer
// (the only source for it on a non-system app) and prints "CURSOR <x> <y>".
static void query_cursor(void) {
    FILE *p = popen("dumpsys SurfaceFlinger 2>/dev/null", "r");
    if (!p) { out("CURSOR -1 -1"); return; }
    char line[512];
    int near_sprite = 0, rows = 0;
    double x = -1, y = -1;
    while (fgets(line, sizeof(line), p)) {
        if (!near_sprite) {
            if (strstr(line, "Sprite")) near_sprite = 1;
            continue;
        }
        double a, b, c2;
        if (sscanf(line, " %lf %lf %lf", &a, &b, &c2) == 3) {
            if (rows == 0) { x = c2; rows = 1; }
            else if (rows == 1) { y = c2; rows = 2; break; }
        }
    }
    pclose(p);
    out("CURSOR %.0f %.0f", x, y);
}

"""
    c = c.replace("static void spawn_injector(void) {", q + "static void spawn_injector(void) {", 1)
    c = c.replace("        case 'E': {", """        case 'W':
            query_cursor();
            break;
        case 'E': {""", 1)
    io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
    print("helper W added")

# ---------- RootInput: expose it ----------
rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
if "onCursorPos" not in r:
    r = r.replace("        fun onReady()", "        fun onReady()\n        fun onCursorPos(x: Float, y: Float)", 1)
    r = r.replace('            line.startsWith("ERR ") -> {', """            line.startsWith("CURSOR ") -> {
                val p = line.split(' ')
                if (p.size >= 3) {
                    val x = p[1].toFloatOrNull() ?: -1f
                    val y = p[2].toFloatOrNull() ?: -1f
                    if (x >= 0f && y >= 0f) listener.onCursorPos(x, y)
                }
            }
            line.startsWith("ERR ") -> {""", 1)
    r = r.replace("    fun regrab() = send(\"R\")", "    fun regrab() = send(\"R\")\n\n    /** ask the helper for the real system pointer position */\n    fun queryCursor() = send(\"W\")", 1)
    io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput CURSOR ok")

# ---------- service: wire the callback + request on mouse-mode start ----------
sp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
v = io.open(sp, encoding="utf-8").read()
if "override fun onCursorPos" not in v:
    v = v.replace("    override fun onDevicesChanged(names: List<String>) {",
"""    override fun onCursorPos(x: Float, y: Float) {
        engine?.moveTo(x, y)
        Log.i(TAG, "cursor synced to $x,$y")
    }

    override fun onDevicesChanged(names: List<String>) {""", 1)
    v = v.replace("""            if (root?.helperReady == true) root?.grab() else updateFocusCatchers()""",
"""            if (root?.helperReady == true) {
                root?.grab()
                root?.queryCursor()   // sync our tracked position with the real pointer
            } else {
                updateFocusCatchers()
            }""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(v)
    print("service cursor sync ok")
