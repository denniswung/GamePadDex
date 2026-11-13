import io, sys
B = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
E = B + "EngineService.kt"; R = B + "RootInput.kt"; S = B + "EngineState.kt"; P = B + "Prefs.kt"; C = B + "ConfigActivity.kt"

def rep(path, old, new, tag, optional=False):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        if optional:
            print("skip", tag); return
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# ---- EngineService: no focus queries ----
rep(E, """        if (!focusSent || focusSentValue != prefs.focusScroll) {
            focusSent = true
            focusSentValue = prefs.focusScroll
            root.focusEnable(prefs.focusScroll)
        }
        if (prefs.focusScroll && ny != 0f && nowMs - lastFocusReqAt > 1500) {
            lastFocusReqAt = nowMs
            root.focusRefresh()
        }
        // wheel scrolling first parks the pointer inside the focused list;
        // the rectangle only arrives ~2 s after the first query, so retry
        if (prefs.focusScroll && !prefs.vTouchScroll && ny != 0f && nowMs - lastAnchorAt > 500) {
            lastAnchorAt = nowMs
            root.focusAnchor()
        }
""", "", "engine focus calls")

rep(E, """    /** 控件级焦点: throttle for the async accessibility query */
    private var lastFocusReqAt = 0L
    private var lastAnchorAt = 0L
    private var focusSent = false
    private var focusSentValue = true
""", "", "engine focus fields")

# ---- RootInput: drop focus protocol ----
rep(R, """    /** enable/disable control-level focus inside the helper */
    fun focusEnable(on: Boolean) = send("c " + if (on) 1 else 0)

    /** refresh the cached scrollable-control rectangle (async, ~2 s) */
    fun focusRefresh() = send("q")

    /** move the pointer into the focused list before a wheel scroll */
    fun focusAnchor() = send("n")

""", "", "root focus cmds")

rep(R, """            line.startsWith("FOCUS ") -> {
                val p = line.removePrefix("FOCUS ").trim()
                if (p == "none") {
                    EngineState.focusRect = null
                } else {
                    val parts = p.split(' ')
                    if (parts.size >= 4) {
                        val x1 = parts[0].toIntOrNull()
                        val y1 = parts[1].toIntOrNull()
                        val x2 = parts[2].toIntOrNull()
                        val y2 = parts[3].toIntOrNull()
                        if (x1 != null && y1 != null && x2 != null && y2 != null) {
                            EngineState.focusRect = intArrayOf(x1, y1, x2, y2)
                        }
                    }
                }
            }
            line.startsWith("FOCUS_SET ") || line.startsWith("FOCUS_NONE") ||
                line.startsWith("FOCUS_ANCHOR ") -> Log.i(TAG, "focus: $line")
""", "", "root focus parse")

# ---- EngineState: drop focusRect ----
rep(S, """
    /** cached scrollable-control rectangle from the accessibility tree */
    @Volatile var focusRect: IntArray? = null
""", "", "state focusRect")

# ---- Prefs: drop focusScroll ----
rep(P, """
    /** scroll/swipe acts on the scrollable control under the pointer (控件级焦点) */
    var focusScroll: Boolean
        get() = shared.getBoolean(KEY_FOCUS_SCROLL, true)
        set(v) = shared.edit().putBoolean(KEY_FOCUS_SCROLL, v).apply()
""", "", "prefs focusScroll")

rep(P, '        const val KEY_FOCUS_SCROLL = "focus_scroll"\n', "", "prefs key")

# export snapshot references it
rep(P, "        o.put(KEY_FOCUS_SCROLL, focusScroll)\n", "", "prefs export key")

# ---- ConfigActivity: status row + toggle ----
rep(C, """            infoRow("链路自检", statusCaps!!),
            infoRow("滚动焦点", statusFocus!!),
""", """            infoRow("链路自检", statusCaps!!),
""", "ui status row")

rep(C, """        statusFocus = valueView()
        statusFocus!!.text = "—"
""", "", "ui status field init")

rep(C, """    private var statusFocus: TextView? = null
""", "", "ui status field")

rep(C, """        val fr = EngineState.focusRect
        statusFocus?.text = if (fr == null || fr.size < 4) {
            "未捕获（滚动一次后更新）"
        } else {
            "${fr[0]},${fr[1]} - ${fr[2]},${fr[3]}"
        }
""", "", "ui status refresh")

rep(C, """            switchRow(
                "控件级焦点",
                "滑动/滚动作用于指针所在的可滚动控件；关闭则用任务范围",
                prefs.focusScroll,
            ) { v -> prefs.focusScroll = v },
""", "", "ui toggle")

print("done")
