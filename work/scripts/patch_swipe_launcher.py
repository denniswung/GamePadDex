import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
e = io.open(E, encoding="utf-8").read()

old = """    private fun doSwipe(vertical: Boolean, dir: Int, slow: Boolean = false, widthPct: Int = 0) {
        if (dir == 0) return
        val now = SystemClock.elapsedRealtime()
        if (now < swipeCooldownUntil) return
        val display = activeDisplay()"""
new = """    /** 前台是不是桌面（桌面没有可滚动内容，下滑手势会被它当成「拉通知栏」） */
    private fun launcherForeground(): Boolean {
        val p = EngineState.topPackage.lowercase()
        return p.contains("launcher") || p.endsWith(".home") || p.contains("flauncher")
    }

    private fun doSwipe(vertical: Boolean, dir: Int, slow: Boolean = false, widthPct: Int = 0) {
        if (dir == 0) return
        val now = SystemClock.elapsedRealtime()
        if (now < swipeCooldownUntil) return
        // 桌面：没有可滚内容，滑动只会触发系统手势（下滑拉出状态栏）。
        // 交回上层虚拟控制器：发方向键，让系统自己做焦点导航。
        if (launcherForeground()) {
            val arrow = when {
                vertical && dir > 0 -> Action.ARROW_DOWN
                vertical -> Action.ARROW_UP
                dir > 0 -> Action.ARROW_RIGHT
                else -> Action.ARROW_LEFT
            }
            actions.fire(arrow, "")
            swipeCooldownUntil = now + 160
            Log.i(TAG, "launcher foreground -> arrow instead of $dir swipe")
            return
        }
        val display = activeDisplay()"""
if old not in e:
    print("MISS head"); sys.exit(1)
e = e.replace(old, new, 1)

# 光标锚定：不再强制百分比起点，交给助手用指针位置
old2 = """            val pct = if (slow) (if (dir > 0) 40 else 60)
            else (if (dir > 0) 30 else 70)
            root.swipeV(display, if (dir > 0) dist else -dist, ms, w, h, pct)"""
new2 = """            // -1 = 以光标为锚点（在任务内时），助手只在光标不可用时退回任务中心
            root.swipeV(display, if (dir > 0) dist else -dist, ms, w, h, -1)"""
if old2 not in e:
    print("MISS v"); sys.exit(1)
e = e.replace(old2, new2, 1)

old3 = """            val pct = if (slow) (if (dir > 0) 40 else 60)
            else (if (dir > 0) 25 else 75)
            root.swipeH(display, dir * dist, ms, w, h, pct)"""
new3 = """            root.swipeH(display, dir * dist, ms, w, h, -1)"""
if old3 not in e:
    print("MISS h"); sys.exit(1)
e = e.replace(old3, new3, 1)

io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("ok")
