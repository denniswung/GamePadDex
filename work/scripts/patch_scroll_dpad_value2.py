import io, sys
BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
E = BASE + "EngineService.kt"
P = BASE + "Prefs.kt"

# ---------------- Prefs：每槽参数 ----------------
p = io.open(P, encoding="utf-8").read()
if "paramKey" not in p:
    p = p.replace('        fun longKey(button: String) = "lng_$button"',
'''        fun longKey(button: String) = "lng_$button"

        /** 每个映射槽的"参数"（KEY_COMBO = 快捷键，OPEN_APP = 目标包名） */
        fun paramKey(button: String) = "par_$button"

        fun paramDblKey(button: String) = "par_dbl_$button"

        fun paramLngKey(button: String) = "par_lng_$button"''', 1)
    p = p.replace('    fun setAction(button: String, action: String) {',
'''    fun param(button: String): String = shared.getString(paramKey(button), "") ?: ""

    fun setParam(button: String, v: String) = shared.edit().putString(paramKey(button), v).apply()

    fun paramDbl(button: String): String = shared.getString(paramDblKey(button), "") ?: ""

    fun setParamDbl(button: String, v: String) = shared.edit().putString(paramDblKey(button), v).apply()

    fun paramLng(button: String): String = shared.getString(paramLngKey(button), "") ?: ""

    fun setParamLng(button: String, v: String) = shared.edit().putString(paramLngKey(button), v).apply()

    fun setAction(button: String, action: String) {''', 1)
    io.open(P, "w", encoding="utf-8", newline="\n").write(p)
    print("prefs ok")

# ---------------- Engine ----------------
s = io.open(E, encoding="utf-8").read()

def rep(old, new, tag):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1); print("ok", tag)

# 1) 右摇杆滚动方向
rep('''                    val down = ny <= 0
                    val dist = if (down) (h * 0.45f).toInt().coerceIn(320, 1200)
                               else (h * 0.35f).toInt().coerceIn(360, 1200)
                    val pct = if (down) 3 else 65
                    val ms = if (down) 200 else 450
                    val dy = if (down) dist else -dist
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + if (down) swipeRepeatMs() else ms + 40L''',
'''                    // 摇杆向上 = 想看上面的内容 = 手指向下拖（内容跟手指往下走）；
                    // 摇杆向下 = 手指向上拖。起点用 30% / 65%，不要用 3%：
                    // 从顶部手势区起手会被系统当成「拉通知栏」，页面完全不动。
                    val up = ny < 0
                    val dist = (h * (if (up) 0.35f else 0.30f)).toInt().coerceIn(320, 1100)
                    val pct = if (up) 30 else 65
                    val dy = if (up) dist else -dist
                    val ms = if (up) 220 else 380
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + ms + 30L''', "right stick scroll")

# 2) d-pad 连发字段
if "dpadRepeatRunnable" not in s:
    rep("    private var zooming = false",
        '''    private var zooming = false
    /** d-pad 长按连发 */
    private var dpadRepeatRunnable: Runnable? = null
    private var dpadRepeatName: String? = null''', "dpad fields")

# 3) 参数取值函数 + 连发方法
if "private fun valueFor(" not in s:
    rep("    /** actions that fire once and do not need press/hold semantics */",
'''    /** 每个映射槽的参数：KEY_COMBO = 快捷键，OPEN_APP = 目标包名 */
    private fun valueFor(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.param(name)
        else -> prefs.combo(name)
    }

    private fun dblValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.paramDbl(name)
        Action.KEY_COMBO -> prefs.combo(name)
        else -> ""
    }

    private fun longValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.paramLng(name)
        Action.KEY_COMBO -> prefs.combo(name)
        else -> ""
    }

    /** d-pad 按住连发（键盘式）：400 ms 后每 110 ms 一次 */
    private fun startDpadRepeat(name: String, mapped: String) {
        if (!navActive()) return
        cancelDpadRepeat()
        dpadRepeatName = name
        val r = object : Runnable {
            override fun run() {
                if (dpadRepeatName != name || !pressedButtons.contains(name)) return
                if (!modeOn || !root.helperReady) return
                actions.fire(mapped, "")
                handler.postDelayed(this, 110L)
            }
        }
        dpadRepeatRunnable = r
        handler.postDelayed(r, 400L)
    }

    private fun cancelDpadRepeat(name: String? = null) {
        if (name != null && dpadRepeatName != name) return
        dpadRepeatRunnable?.let { handler.removeCallbacks(it) }
        dpadRepeatRunnable = null
        dpadRepeatName = null
    }

    /** actions that fire once and do not need press/hold semantics */''', "value/repeat helpers")

# 4) fireSingle 使用参数 + 启动连发
rep('            else -> actions.fire(mapped, prefs.combo(name))\n        }\n        if (!isOneShot(mapped) && mapped != Action.TOGGLE) startedHolds.add(name)',
    '''            else -> actions.fire(mapped, valueFor(name, mapped))
        }
        if (mapped.startsWith("arrow_")) startDpadRepeat(name, mapped)
        if (!isOneShot(mapped) && mapped != Action.TOGGLE) startedHolds.add(name)''', "fireSingle value/repeat")

# 5) 双击 / 长按 带参数
rep('''                        if (dbl == Action.KEY_COMBO) actions.fire(dbl, prefs.combo(name))
                        else actions.fire(dbl, "")''',
    '''                        actions.fire(dbl, dblValue(name, dbl))''', "double value")
rep('            if (modeOn && root.helperReady) actions.fire(action, "")',
    '            if (modeOn && root.helperReady) actions.fire(action, longValue(name, action))', "long value")

# 6) 释放 / 清理时停止连发
rep('''        } else {
            stopWheel(name)
            releaseMixFor(name)''',
'''        } else {
            cancelDpadRepeat(name)
            stopWheel(name)
            releaseMixFor(name)''', "release stop repeat")
rep("        startedHolds.clear()", "        startedHolds.clear()\n        cancelDpadRepeat()", "clear stop repeat")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("engine written")
