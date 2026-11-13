import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# a control rectangle stays valid longer: re-dumping costs ~2 s
rep(H, "#define FOCUS_TTL  5000", "#define FOCUS_TTL  15000", "ttl")

# log the focus age with the swipe so the tests can tell why it fell back
rep(H, '''        out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d) rc=%d", display, x, y, x2, y2,
            focusUsed ? "focus" : "task", bx1, bx2, by1, by2, rc);''',
'''        out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d age=%lld) rc=%d", display, x, y, x2, y2,
            focusUsed ? "focus" : "task", bx1, bx2, by1, by2,
            focusUsed ? now_ms() - g_focus_at : -1LL, rc);''', "swipe rc age")

rep(H, '''    out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d) async", display, x, y, x2, y2,
        focusUsed ? "focus" : "task", bx1, bx2, by1, by2);''',
'''    out("SWIPE %d %d,%d -> %d,%d (%s %d..%d / %d..%d age=%lld) async", display, x, y, x2, y2,
        focusUsed ? "focus" : "task", bx1, bx2, by1, by2,
        focusUsed ? now_ms() - g_focus_at : -1LL);''', "swipe async age")

# wheel mode: re-anchor periodically so the first dump's result is applied
rep(E, """        if (prefs.focusScroll && ny != 0f && nowMs - lastFocusReqAt > 2000) {
            lastFocusReqAt = nowMs
            root.focusRefresh()
        }
        if (!prefs.vTouchScroll && ny != 0f && !wheelAnchored) {
            wheelAnchored = true
            root.focusAnchor()
        } else if (ny == 0f) {
            wheelAnchored = false
        }""",
"""        if (prefs.focusScroll && ny != 0f && nowMs - lastFocusReqAt > 1500) {
            lastFocusReqAt = nowMs
            root.focusRefresh()
        }
        // wheel scrolling first parks the pointer inside the focused list;
        // the rectangle only arrives ~2 s after the first query, so retry
        if (prefs.focusScroll && !prefs.vTouchScroll && ny != 0f && nowMs - lastAnchorAt > 500) {
            lastAnchorAt = nowMs
            root.focusAnchor()
        }""", "anchor throttle")

rep(E, """    private var wheelAnchored = false""",
"""    private var lastAnchorAt = 0L""", "field rename")

print("done")
