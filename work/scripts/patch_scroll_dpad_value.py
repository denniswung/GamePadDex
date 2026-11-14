import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()

# ---------- 1) 右摇杆滚动方向修正 ----------
old = '''                    val down = ny <= 0
                    val dist = if (down) (h * 0.45f).toInt().coerceIn(320, 1200)
                               else (h * 0.35f).toInt().coerceIn(360, 1200)
                    val pct = if (down) 3 else 65
                    val ms = if (down) 200 else 450
                    val dy = if (down) dist else -dist
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + if (down) swipeRepeatMs() else ms + 40L'''
new = '''                    // 摇杆向上 = 想看上面的内容 = 手指向下拖（内容跟随手指往下走）；
                    // 摇杆向下 = 手指向上拖。起点用 30% / 65%，不要用 3%——那会从
                    // 顶部手势区起手，被系统当成「拉通知栏」，页面就完全不动。
                    val up = ny < 0
                    val dist = (h * (if (up) 0.35f else 0.30f)).toInt().coerceIn(320, 1100)
                    val pct = if (up) 30 else 65
                    val dy = if (up) dist else -dist
                    val ms = if (up) 220 else 380
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + ms + 30L'''
if old not in s:
    print("MISS scroll"); sys.exit(1)
s = s.replace(old, new, 1)
print("scroll ok")

# ---------- 2) D-pad 连发 ----------
if "dpadRepeatRunnable" not in s:
    anchor = "    private var zooming = false"
    s = s.replace(anchor, anchor + '''
    /** d-pad 长按连发 */
    private var dpadRepeatRunnable: Runnable? = null
    private var dpadRepeatName: String? = null''', 1)
    print("dpad fields ok")

    # 连发调度：按下 400ms 后每 110ms 重复
    s = s.replace("    /** actions that fire once and do not need press/hold semantics */",
'''    /** d-pad 按住连发（键盘式重复）：首次 400 ms，之后每 110 ms 一次 */
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

    /** actions that fire once and do not need press/hold semantics */''', 1)
    print("dpad methods ok")

    # fireSingle：方向键按下后开始连发
    s = s.replace('''            else -> actions.fire(mapped, prefs.combo(name))
        }
        if (!isOneShot(mapped) && mapped != Action.TOGGLE) startedHolds.add(name)''',
'''            else -> actions.fire(mapped, valueFor(name, mapped))
        }
        if (mapped.startsWith("arrow_")) startDpadRepeat(name, mapped)
        if (!isOneShot(mapped) && mapped != Action.TOGGLE) startedHolds.add(name)''', 1)
    print("dpad start ok")

    # 释放时停止连发
    s = s.replace('''        } else {
            stopWheel(name)
            releaseMixFor(name)''',
'''        } else {
            cancelDpadRepeat(name)
            stopWheel(name)
            releaseMixFor(name)''', 1)
    print("dpad stop ok")

    # clearPressedState 也要停
    s = s.replace("        startedHolds.clear()", "        startedHolds.clear()\n        cancelDpadRepeat()", 1)
    print("dpad clear ok")

# ---------- 3) 每个映射槽自己的「打开目标应用」参数 ----------
if "valueFor(" not in s:
    s = s.replace("    /** actions that fire once and do not need press/hold semantics */",
'''    /** 每个映射槽的"参数"：KEY_COMBO 用快捷键，OPEN_APP 用目标包名 */
    private fun valueFor(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.param(name)
        else -> prefs.combo(name)
    }

    /** actions that fire once and do not need press/hold semantics */''', 1)
    print("valueFor ok")

# 双击 / 长按 / 组合 的 action 调用带上参数
s = s.replace('if (dbl == Action.KEY_COMBO) actions.fire(dbl, prefs.combo(name))\n                        else actions.fire(dbl, "")',
              'actions.fire(dbl, dblValue(name, dbl))', 1)
s = s.replace('            if (modeOn && root.helperReady) actions.fire(action, "")',
              '            if (modeOn && root.helperReady) actions.fire(action, longValue(name, action))', 1)

if "dblValue(" not in s:
    s = s.replace("    private fun valueFor(name: String, mapped: String): String = when (mapped) {",
'''    private fun dblValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.paramDbl(name)
        else -> if (mapped == Action.KEY_COMBO) prefs.combo(name) else ""
    }

    private fun longValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.paramLng(name)
        else -> if (mapped == Action.KEY_COMBO) prefs.combo(name) else ""
    }

    private fun valueFor(name: String, mapped: String): String = when (mapped) {''', 1)
    print("dbl/long value ok")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("engine written")
