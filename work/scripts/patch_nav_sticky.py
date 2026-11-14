import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 1) 导航模式不再靠 1.2 秒超时退出：只由「摇杆移动 / 关模式」退出
#    （用户节奏：d-pad 选中 → 想一想 → 按 A 确认，1.2 秒远远不够）
rep("""    private fun navActive(): Boolean =
        nativeNav && SystemClock.elapsedRealtime() < navUntil""",
    """    // d-pad 导航模式：进入后一直有效，直到移动摇杆（想用鼠标）或关闭鼠标模式。
    // 不再用 1.2 秒超时——"d-pad 选中完再按 A 确认"是人的正常节奏，几秒钟很常见。
    private fun navActive(): Boolean = nativeNav""", "navActive")

rep("""    private fun markNativeNav() {""",
    """    private fun markNativeNav() {
        // 新的 d-pad 按下 = 明确要用方向键导航（刷新一次时间戳仅用于日志/兼容）""", "markNativeNav")

# 2) 时间戳只做日志字段（保留变量，避免其他引用编译失败）
rep("""        nativeNav = true
        navUntil = SystemClock.elapsedRealtime() + prefs.focusWindowMs()""",
    """        nativeNav = true
        navUntil = SystemClock.elapsedRealtime() + prefs.focusWindowMs()
        Log.i(TAG, "A 确认模式：d-pad 导航中（移动左摇杆回到鼠标点击）")""", "navUntil")

# 3) step() 里去掉超时退出，只保留摇杆移动退出
rep("""        // leaving the native d-pad navigation: any stick movement resumes the
        // mouse mode (A goes back to being a mouse click)
        if (nativeNav && !navActive()) {
            nativeNav = false
            Log.i(TAG, "native navigation OFF (window elapsed)")
        }""",
    """        // d-pad 导航模式只由摇杆移动退出（时间到不再自动退出）""", "stepTimeout")

# 4) A 按下时打印判定依据，方便以后排查
rep("""            Action.LEFT -> {""",
    """            Action.LEFT -> {
                Log.i(TAG, "A pressed: nativeNav=$nativeNav navActive=${navActive()} leftClickTouch=${prefs.leftClickTouch}")""", "aDebug")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
