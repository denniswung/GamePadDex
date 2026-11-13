import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# ---- helper: focus enable flag + pending anchor ----
rep(H, "static pid_t g_focus_child = 0;",
"""static pid_t g_focus_child = 0;
/* the app can disable control-level focus (falls back to task bounds) */
static int g_focus_enabled = 1;
static int g_anchor_pending = 0;""", "flags")

rep(H, """static int focus_valid(void) {
    if (g_fx1 < 0 || g_fx2 <= g_fx1) return 0;""",
"""static int focus_valid(void) {
    if (!g_focus_enabled) return 0;
    if (g_fx1 < 0 || g_fx2 <= g_fx1) return 0;""", "valid gate")

# child applies a pending anchor right after a successful dump
rep(H, """    if (focus_parse(FOCUS_UI, px, py, &x1, &y1, &x2, &y2)) {
        focus_write(x1, y1, x2, y2);
        out("FOCUS_SET %d,%d %d,%d (ptr %d,%d)", x1, y1, x2, y2, px, py);
    } else {""",
"""    if (focus_parse(FOCUS_UI, px, py, &x1, &y1, &x2, &y2)) {
        focus_write(x1, y1, x2, y2);
        out("FOCUS_SET %d,%d %d,%d (ptr %d,%d)", x1, y1, x2, y2, px, py);
        if (g_anchor_pending) {
            g_anchor_pending = 0;
            int cx = (x1 + x2) / 2, cy = (y1 + y2) / 2;
            if (px >= 0 && py >= 0) {
                cmd_mouse_move(cx - px, cy - py);
                out("FOCUS_ANCHOR %d,%d -> %d,%d", px, py, cx, cy);
            }
        }
    } else {""", "pending anchor")

# anchor command: if the rectangle is not there yet, remember the request
rep(H, """static void focus_anchor(void) {
    focus_load();
    if (!focus_valid()) return;""",
"""static void focus_anchor(void) {
    focus_load();
    if (!focus_valid()) {
        g_anchor_pending = 1;
        focus_refresh();
        return;
    }""", "anchor pending set")

# 'c' command to toggle control-level focus
rep(H, """        case 'q':""",
"""        case 'c': {
            int on = 1;
            sscanf(line, "%d", &on);
            g_focus_enabled = on ? 1 : 0;
            out("FOCUS_ENABLED %d", g_focus_enabled);
            break;
        }
        case 'q':""", "c command")

# ---- app: sync the toggle + send the anchor burst ----
rep(R, """    /** refresh the cached scrollable-control rectangle (async, ~2 s) */""",
"""    /** enable/disable control-level focus inside the helper */
    fun focusEnable(on: Boolean) = send("c " + if (on) 1 else 0)

    /** refresh the cached scrollable-control rectangle (async, ~2 s) */""", "root focusEnable")

rep(E, """        if (prefs.focusScroll && ny != 0f && nowMs - lastFocusReqAt > 1500) {""",
"""        if (!focusSent || focusSentValue != prefs.focusScroll) {
            focusSent = true
            focusSentValue = prefs.focusScroll
            root.focusEnable(prefs.focusScroll)
        }
        if (prefs.focusScroll && ny != 0f && nowMs - lastFocusReqAt > 1500) {""", "sync toggle")

rep(E, """    private var lastAnchorAt = 0L""",
"""    private var lastAnchorAt = 0L
    private var focusSent = false
    private var focusSentValue = true""", "fields")

print("done")
