import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
s = io.open(E, encoding="utf-8").read()

def rep(old, new, tag, path=None):
    global s
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    print("ok", tag)

# ---------- A1. One Euro: reset() + 死区内硬归零，消除松杆后的“滑行” ----------
rep("""        fun filter(x: Double, dt: Double): Double {""",
"""        /** 摇杆回中时调用：丢弃历史，避免残留速度继续推指针（松手滑行） */
        fun reset() {
            xPrev = 0.0
            dxPrev = 0.0
            first = true
        }

        fun filter(x: Double, dt: Double): Double {""", "euro reset")

rep("""        var dx = curve(axes[0] * prefs.sensX(), dead)
        var dy = curve(axes[1] * prefs.sensY(), dead)
        // One Euro: smooths the slow stick, keeps fast flicks responsive
        dx = euroX.filter(dx.toDouble(), dtSec).toFloat()
        dy = euroY.filter(dy.toDouble(), dtSec).toFloat()
        if (dx != 0f || dy != 0f) {""",
"""        var dx = curve(axes[0] * prefs.sensX(), dead)
        var dy = curve(axes[1] * prefs.sensY(), dead)
        if (dx == 0f && dy == 0f) {
            // 摇杆在死区内：立刻清零，不要用滤波器的衰减尾巴继续推指针，
            // 否则松手后指针还会滑出去一段（用户可直接感知的“太滑”）。
            euroX.reset()
            euroY.reset()
        } else {
            // One Euro: smooths the slow stick, keeps fast flicks responsive
            dx = euroX.filter(dx.toDouble(), dtSec).toFloat()
            dy = euroY.filter(dy.toDouble(), dtSec).toFloat()
        }
        if (dx != 0f || dy != 0f) {""", "euro gate")

rep("""                val mx = dx * speed * dtScale
                val my = dy * speed * dtScale
                root.move(mx, my)""",
"""                val mx = dx * speed * dtScale
                val my = dy * speed * dtScale
                // 亚像素抖动不发：1px 的残余移动在慢速下会被看成“滑”
                if (Math.abs(mx) < 0.6f && Math.abs(my) < 0.6f) return
                root.move(mx, my)""", "epsilon")

# ---------- A2. 组合键：参与者必须是“新按下”，防止卡住的 L3 把 Y 变成电源 ----------
rep("""                val leader = leaderOf(keys)
                val direct = keys.first() == leader""",
"""                // 卡住的按键（比如误触后没弹起的 L3）不能把单键动作劫持成组合：
                // 除发起键之外的每个键，都必须是 1.5s 内刚按下的。
                val nowMix = SystemClock.elapsedRealtime()
                val leaderNow = leaderOf(keys)
                val fresh = keys.filter { it != leaderNow }.all { k ->
                    val at = pressAt[k] ?: return@all false
                    nowMix - at <= 1500L
                }
                if (!fresh) continue
                val leader = leaderNow
                val direct = keys.first() == leader""", "fresh guard")

# ---------- A3. 助手重连时清空按键状态 ----------
rep("""        // a (re)started helper has forwarding off: force a re-send
        dpadSent = false""",
"""        // a (re)started helper has forwarding off: force a re-send
        dpadSent = false
        // 助手重启后手柄可能已经断过一轮，之前按下的键不会再有 up 事件：
        // 不清掉会留下“幽灵按键”，把后续单键动作劫持成组合（例如 Y 变成电源）。
        clearPressedState("helper ready")""", "clear on ready")

rep("""    private fun releaseMixFor(name: String) {""",
"""    /** 丢弃所有“按住”状态（断线/重连/卡键自愈时调用） */
    private fun clearPressedState(reason: String) {
        if (pressedButtons.isNotEmpty() || pressedButtons.isNotEmpty()) {
            Log.i(TAG, "clear pressed state ($reason): ${pressedButtons.joinToString(",")}")
        }
        pressedButtons.clear()
        pressAt.clear()
        mixConsumed.clear()
        deferredSingles.clear()
        pendingDowns.keys.toList().forEach { handler.removeCallbacks(pendingDowns.getValue(it) ?: return@forEach) }
        pendingDowns.clear()
        longFired.clear()
        for (i in 0 until Prefs.MIX_COUNT) mixFired[i] = false
        stopMixRepeat()
    }

    private fun releaseMixFor(name: String) {""", "clearPressedState")

# ---------- A4. 卡键自愈：按住超过 15s 的键丢弃 ----------
rep("""        if (mixHoldAction.isNotEmpty()) {""",
"""        // 卡键自愈：真实按键不会按住 15s 以上，超时就当它丢了 up 事件
        if (pressedButtons.isNotEmpty()) {
            val nowStale = SystemClock.elapsedRealtime()
            val stale = pressedButtons.filter { nowStale - (pressAt[it] ?: nowStale) > 15_000L }
            for (k in stale) {
                Log.i(TAG, "stale key dropped: $k (held >15s)")
                pressedButtons.remove(k)
                pressAt.remove(k)
                mixConsumed.remove(k)
                deferredSingles.remove(k)
                longFired.remove(k)
                for (i in 0 until Prefs.MIX_COUNT) if (prefs.mixKeys(i).contains(k)) mixFired[i] = false
            }
        }
        if (mixHoldAction.isNotEmpty()) {""", "stale heal")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)

# ---------- B. LB/RB 单键对调 ----------
p = io.open(P, encoding="utf-8").read()
old_lbrb = """            "lb" -> Action.SCROLL_SWIPE_UP
            "rb" -> Action.SCROLL_SWIPE_DOWN"""
new_lbrb = """            // 用户习惯：RB = 向下浏览（手指上滑），LB = 向上回溯（手指下滑）
            "lb" -> Action.SCROLL_SWIPE_DOWN
            "rb" -> Action.SCROLL_SWIPE_UP"""
if old_lbrb not in p:
    print("MISS lbrb"); sys.exit(1)
p = p.replace(old_lbrb, new_lbrb, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(p)
print("ok lbrb swap")
print("done")
