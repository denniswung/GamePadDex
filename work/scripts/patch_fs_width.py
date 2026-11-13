import io
root = r"E:\Dennis\GamePadDex复刻\project"

cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
c = c.replace("static void caption_fullscreen_click(int displayId) {",
              "static void caption_fullscreen_click(int displayId, int screen_w) {", 1)
c = c.replace("""    int x = right - 84;
    int y = top + 30;""",
"""    /* maximized windows lose the extras button, so the fullscreen icon sits
       115px from the display edge; windowed ones 84px from the window edge */
    int x;
    if (screen_w > 0 && right >= screen_w - 10) x = screen_w - 115;
    else x = right - 84;
    int y = top + 30;""", 1)
c = c.replace("""        case 'J': {
            int jd = 0;
            if (sscanf(line, "%d", &jd) == 1 && jd > 0) caption_fullscreen_click(jd);
            break;
        }""",
"""        case 'J': {
            int jd = 0, jw = 0;
            int n = sscanf(line, "%d %d", &jd, &jw);
            if (n >= 1 && jd > 0) caption_fullscreen_click(jd, n >= 2 ? jw : 0);
            break;
        }""", 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
print("helper J takes the screen width")

rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
r = r.replace("""    fun fullscreenClick(displayId: Int): Boolean {
        if (!isRunning) return false
        send("J $displayId")""",
"""    fun fullscreenClick(displayId: Int, screenWidth: Int = 0): Boolean {
        if (!isRunning) return false
        send("J $displayId $screenWidth")""", 1)
io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
print("rootinput passes width")

sp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
s = s.replace("val rootOk = try { root?.fullscreenClick(dispNow) ?: false }",
              "val rootOk = try { root?.fullscreenClick(dispNow, screenWidth ?: 0) ?: false }", 1)
# expose the engine width
if "val screenWidth: Int?" not in s:
    s = s.replace("    /** apply the \"block stock gamepad input\" preference right away */",
"""    /** width of the display we control (for position maths in the helper) */
    val screenWidth: Int?
        get() = engine?.displayWidth

    /** apply the "block stock gamepad input" preference right away */""", 1)
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service passes width")