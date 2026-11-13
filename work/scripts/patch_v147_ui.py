import io, sys
C = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt"

def rep(old, new, tag):
    s = io.open(C, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(C, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# status rows: capability self-test + focus rectangle
rep("""        content.addView(card(
            infoRow("Root 助手", statusHelper!!),
            infoRow("手柄", statusDevices!!),
            infoRow("鼠标模式", statusMode!!),
            infoRow("指针位置", pointerText!!),
        ))""",
"""        statusCaps = valueView()
        statusCaps!!.text = "—"
        statusFocus = valueView()
        statusFocus!!.text = "—"
        content.addView(card(
            infoRow("Root 助手", statusHelper!!),
            infoRow("手柄", statusDevices!!),
            infoRow("鼠标模式", statusMode!!),
            infoRow("指针位置", pointerText!!),
            infoRow("链路自检", statusCaps!!),
            infoRow("滚动焦点", statusFocus!!),
        ))""", "status rows")

rep("""    private var statusHelper: TextView? = null""",
"""    private var statusHelper: TextView? = null
    private var statusCaps: TextView? = null
    private var statusFocus: TextView? = null""", "status fields")

# focus toggle
rep("""            switchRow("反向滚动", null, prefs.invertScroll) { v -> prefs.invertScroll = v },""",
"""            switchRow("反向滚动", null, prefs.invertScroll) { v -> prefs.invertScroll = v },
            switchRow(
                "控件级焦点",
                "滑动/滚动作用于指针所在的可滚动控件；关闭则用任务范围",
                prefs.focusScroll,
            ) { v -> prefs.focusScroll = v },""", "focus toggle")

print("done")
