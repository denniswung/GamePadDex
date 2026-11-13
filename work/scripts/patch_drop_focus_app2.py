import io
B = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
E = B + "EngineService.kt"; R = B + "RootInput.kt"; S = B + "EngineState.kt"; P = B + "Prefs.kt"; C = B + "ConfigActivity.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("skip", tag); return
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

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

rep(S, """
    /** cached scrollable-control rectangle from the accessibility tree */
    @Volatile var focusRect: IntArray? = null
""", "", "state focusRect")

rep(P, """
    /** scroll/swipe acts on the scrollable control under the pointer (控件级焦点) */
    var focusScroll: Boolean
        get() = shared.getBoolean(KEY_FOCUS_SCROLL, true)
        set(v) = shared.edit().putBoolean(KEY_FOCUS_SCROLL, v).apply()
""", "", "prefs focusScroll")

rep(P, '        const val KEY_FOCUS_SCROLL = "focus_scroll"\n', "", "prefs key")
rep(P, "        o.put(KEY_FOCUS_SCROLL, focusScroll)\n", "", "prefs export key")

rep(C, """            infoRow("链路自检", statusCaps!!),
            infoRow("滚动焦点", statusFocus!!),
""", """            infoRow("链路自检", statusCaps!!),
""", "ui status row")

rep(C, """        statusFocus = valueView()
        statusFocus!!.text = "—"
""", "", "ui status init")

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
