import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
C = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt"

e = io.open(E, encoding="utf-8").read()

# 1) 指针隐藏状态 + 空闲计时
anchor = "    private var lastPtrLogAt = 0L"
if anchor not in e:
    print("MISS anchor"); sys.exit(1)
e = e.replace(anchor, anchor + """
    /** 系统指针是否已被我们隐藏（销毁虚拟鼠标 = 没有指针设备 = 指针消失） */
    private var pointerHidden = false
    /** 最近一次"用户操作"时间：摇杆移动/按键/点击，用于空闲自动隐藏 */
    private var lastUserInputAt = 0L""", 1)

# 2) 隐藏/显示
anchor2 = "    /** 调试/测试用：把一条原始命令转发给 root 助手 */"
if anchor2 not in e:
    print("MISS anchor2"); sys.exit(1)
e = e.replace(anchor2, """    /** 隐藏系统指针：销毁虚拟鼠标设备（没有鼠标设备时系统不画指针） */
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

""" + anchor2, 1)

# 3) 空闲自动隐藏 + 任何输入都恢复
anchor3 = "        if (ticks % 120 == 0L) root.queryTop()"
if anchor3 not in e:
    print("MISS anchor3"); sys.exit(1)
e = e.replace(anchor3, """        if (ticks % 120 == 0L) root.queryTop()
        // 空闲自动隐藏指针：一段时间没有任何操作就把虚拟鼠标销毁，
        // 系统没有鼠标设备就不会画指针；下一次操作时再重建。
        run {
            val idleSec = prefs.idleHideSec
            if (idleSec > 0 && modeOn && root.helperReady && pressedButtons.isEmpty()) {
                val nowIdle = SystemClock.elapsedRealtime()
                if (lastUserInputAt == 0L) lastUserInputAt = nowIdle
                if (!pointerHidden && nowIdle - lastUserInputAt > idleSec * 1000L) hidePointer()
            }
        }""", 1)

# 4) 输入时恢复指针
anchor4 = "        val dead = prefs.deadzone / 1000f\n        val dtSec"
if anchor4 not in e:
    print("MISS anchor4"); sys.exit(1)
e = e.replace(anchor4, """        val dead = prefs.deadzone / 1000f
        if (Math.abs(axes[0]) > dead || Math.abs(axes[1]) > dead) {
            lastUserInputAt = SystemClock.elapsedRealtime()
            showPointer()
        }
        val dtSec""", 1)

# 5) 鼠标模式关闭时隐藏、打开时恢复
if "if (!on) hidePointer()" not in e:
    e = e.replace("""    private fun setMode(on: Boolean) {""",
"""    private fun setMode(on: Boolean) {
        if (!on) hidePointer() else showPointer()""", 1)

io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("engine ok")

p = io.open(P, encoding="utf-8").read()
if "idleHideSec" not in p:
    p = p.replace('        const val KEY_FOCUS_WINDOW_MS = "focus_window_ms"',
                  '        const val KEY_FOCUS_WINDOW_MS = "focus_window_ms"\n        const val KEY_IDLE_HIDE_SEC = "idle_hide_sec"', 1)
    p = p.replace("""    fun focusWindowMs(): Long =""",
"""    /** 空闲多少秒后隐藏系统指针（0 = 不隐藏） */
    val idleHideSec: Int
        get() = shared.getInt(KEY_IDLE_HIDE_SEC, 8).coerceIn(0, 60)

    fun setIdleHideSec(v: Int) = shared.edit().putInt(KEY_IDLE_HIDE_SEC, v.coerceIn(0, 60)).apply()

    fun focusWindowMs(): Long =""", 1)
    p = p.replace("        o.put(KEY_FOCUS_WINDOW_MS, focusWindowMs().toInt())",
                  "        o.put(KEY_FOCUS_WINDOW_MS, focusWindowMs().toInt())\n        o.put(KEY_IDLE_HIDE_SEC, idleHideSec)", 1)
    io.open(P, "w", encoding="utf-8", newline="\n").write(p)
    print("prefs ok")

c = io.open(C, encoding="utf-8").read()
if "空闲隐藏指针" not in c:
    c = c.replace('''            sliderRow("方向键焦点窗口", 3, 50,''',
'''            sliderRow("空闲隐藏指针", 0, 30, prefs.idleHideSec, " s") { v -> prefs.setIdleHideSec(v) },
            sliderRow("方向键焦点窗口", 3, 50,''', 1)
    io.open(C, "w", encoding="utf-8", newline="\n").write(c)
    print("config ok")
