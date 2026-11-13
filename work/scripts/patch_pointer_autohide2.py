import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
C = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt"

e = io.open(E, encoding="utf-8").read()

def rep(old, new, tag):
    global e
    if old not in e:
        print("MISS", tag); sys.exit(1)
    e = e.replace(old, new, 1)
    print("ok", tag)

rep("    private var lastPtrLogAt = 0L",
    """    private var lastPtrLogAt = 0L
    /** 系统指针是否已被我们隐藏（销毁虚拟鼠标 = 没有指针设备 = 指针消失） */
    private var pointerHidden = false
    /** 最近一次用户操作时间（摇杆/按键/点击），用于空闲自动隐藏 */
    private var lastUserInputAt = 0L""", "fields")

rep("    /** 调试/测试用：把一条原始命令转发给 root 助手 */",
    """    /** 隐藏系统指针：销毁虚拟鼠标设备（没有鼠标设备时系统不画指针） */
    private fun hidePointer() {
        if (pointerHidden || !root.helperReady) return
        root.raw("h")
        pointerHidden = true
        Log.i(TAG, "pointer hidden (mouse device destroyed)")
    }

    /** 恢复指针：重建虚拟鼠标 */
    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false
        Log.i(TAG, "pointer shown (mouse device recreated)")
    }

    /** 调试/测试用：把一条原始命令转发给 root 助手 */""", "hide/show")

rep("        if (ticks % 125 == 0L && root.helperReady) root.queryTop()",
    """        if (ticks % 125 == 0L && root.helperReady) root.queryTop()
        // 空闲自动隐藏指针：一段时间没有任何操作就销毁虚拟鼠标（系统就没指针可画），
        // 下次摇杆/按键操作时自动重建。
        run {
            val idleSec = prefs.idleHideSec
            if (idleSec > 0 && modeOn && root.helperReady && pressedButtons.isEmpty()) {
                val nowIdle = SystemClock.elapsedRealtime()
                if (lastUserInputAt == 0L) lastUserInputAt = nowIdle
                if (!pointerHidden && nowIdle - lastUserInputAt > idleSec * 1000L) hidePointer()
            }
        }""", "idle hide")

rep("        val dead = prefs.deadzone / 1000f\n        val dtSec",
    """        val dead = prefs.deadzone / 1000f
        if (Math.abs(axes[0]) > dead || Math.abs(axes[1]) > dead ||
            Math.abs(axes[12]) > dead || Math.abs(axes[13]) > dead
        ) {
            lastUserInputAt = SystemClock.elapsedRealtime()
            showPointer()
        }
        val dtSec""", "show on input")

rep("    private fun setMode(on: Boolean, force: Boolean = false) {",
    """    private fun setMode(on: Boolean, force: Boolean = false) {
        if (!on) hidePointer() else showPointer()""", "mode hook")

io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("engine written")

p = io.open(P, encoding="utf-8").read()
if "idleHideSec" not in p:
    p = p.replace('        const val KEY_FOCUS_WINDOW_MS = "focus_window_ms"',
                  '        const val KEY_FOCUS_WINDOW_MS = "focus_window_ms"\n        const val KEY_IDLE_HIDE_SEC = "idle_hide_sec"', 1)
    p = p.replace("    fun focusWindowMs(): Long =",
"""    /** 空闲多少秒后隐藏系统指针（0 = 不隐藏） */
    val idleHideSec: Int
        get() = shared.getInt(KEY_IDLE_HIDE_SEC, 8).coerceIn(0, 60)

    fun setIdleHideSec(v: Int) = shared.edit().putInt(KEY_IDLE_HIDE_SEC, v.coerceIn(0, 60)).apply()

    fun focusWindowMs(): Long =""", 1)
    p = p.replace("        o.put(KEY_FOCUS_WINDOW_MS, focusWindowMs().toInt())",
                  "        o.put(KEY_FOCUS_WINDOW_MS, focusWindowMs().toInt())\n        o.put(KEY_IDLE_HIDE_SEC, idleHideSec)", 1)
    io.open(P, "w", encoding="utf-8", newline="\n").write(p)
    print("prefs written")

c = io.open(C, encoding="utf-8").read()
if "空闲隐藏指针" not in c:
    c = c.replace('            sliderRow("方向键焦点窗口", 3, 50,',
'''            sliderRow("空闲隐藏指针", 0, 30, prefs.idleHideSec, " s") { v -> prefs.setIdleHideSec(v) },
            sliderRow("方向键焦点窗口", 3, 50,''', 1)
    io.open(C, "w", encoding="utf-8", newline="\n").write(c)
    print("config written")
