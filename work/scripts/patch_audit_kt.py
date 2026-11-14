import io
BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
E, A, B, C, P, R = (BASE + f for f in (
    "EngineService.kt", "ActionRouter.kt", "ButtonDetailActivity.kt", "ConfigActivity.kt",
    "Prefs.kt", "RootInput.kt"))
fails = []


def patch(path, pairs, name):
    s = io.open(path, encoding="utf-8").read()
    for old, new, tag in pairs:
        if old not in s:
            fails.append(f"{name}:{tag}")
            continue
        s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print(name, "written")


# ---------- EngineService ----------
patch(E, [
    # K1 onReady 重置指针/触摸状态
    ("""    override fun onReady() {
        // 链路自检: report missing root capabilities instead of failing silently
        root.selftest()""",
     """    override fun onReady() {
        // 链路自检: report missing root capabilities instead of failing silently
        root.selftest()
        // 助手重启后鼠标设备可能仍处于「被空闲隐藏」状态，触摸面尺寸也可能变了：
        // 两个状态都重置，保证第一下点击/缩放就正确
        pointerHidden = false
        touchSizeSent = ""
        root.raw("j")""", "onReady"),
    # K2 手柄掉线：把所有按住状态一起释放（否则滚动/按键会一直卡着）
    ("""    override fun onDeviceGone() {
        clearPressedState("device gone")
    }""",
     """    override fun onDeviceGone() {
        clearPressedState("device gone")
        releaseHeld()
    }""", "onDeviceGone"),
    # K3 重复条件笔误
    ("if (pressedButtons.isNotEmpty() || pressedButtons.isNotEmpty()) {",
     "if (pressedButtons.isNotEmpty() || pressedMouse.isNotEmpty()) {", "dupCond"),
    # K4 GUIDE 短按也要走参数解析（映射成"打开目标应用"时不能用 combo 当包名）
    ('                        actions.fire(mapped, prefs.combo("guide"))',
     '                        actions.fire(mapped, valueFor("guide", mapped))', "guideValue"),
    # K8 水平滑动速度接进横向翻页节奏
    ("""    private fun swipeRepeatMs(): Long =
        (620L - prefs.scrollSpeed * 30L).coerceIn(260L, 700L)""",
     """    private fun swipeRepeatMs(): Long =
        (620L - prefs.scrollSpeed * 30L).coerceIn(260L, 700L)

    /** 横向翻页节奏：受「水平滑动速度」控制（原来这个滑杆是无效的） */
    private fun hSwipeRepeatMs(): Long =
        (680L - prefs.hswipeSpeed * 40L).coerceIn(220L, 760L)""", "hswipe"),
    # 横向分支使用 hSwipeRepeatMs
    ("                swipeCooldownUntil = nowH + swipeRepeatMs()",
     "                swipeCooldownUntil = nowH + hSwipeRepeatMs()", "hswipeUse"),
    # 断开连接时也重置指针状态
    ("""    override fun onLinkLost() {""",
     """    override fun onLinkLost() {
        pointerHidden = false
        touchSizeSent = \"\"""", "onLinkLost"),
], "engine")

# ---------- ActionRouter ----------
patch(A, [
    ("""                val pkg = comboValue.ifBlank { prefs.targetPackage }
                if (pkg.isBlank()) log("open app: 该按键还没选目标应用")""",
     """                val pkg = comboValue.ifBlank { prefs.targetPackage }.trim()
                // 没选应用、或把快捷键文本误存成包名时直接报错，不要盲目 am start
                if (pkg.isBlank() || !pkg.contains('.')) log("open app: 未设置有效的目标应用（$pkg）")""", "openapp-validate"),
], "router")

# ---------- ButtonDetailActivity：组合槽也能配「打开目标应用」 ----------
patch(B, [
    ("""                    if (picked == Action.KEY_COMBO) {
                        editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                            prefs.setMixValue(slot, v)
                            rebuild()
                        }
                    } else {
                        rebuild()
                    }""",
     """                    when (picked) {
                        Action.KEY_COMBO -> editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                            prefs.setMixValue(slot, v)
                            rebuild()
                        }
                        Action.OPEN_APP -> pickApp("组合 → 打开哪个应用", prefs.mixValue(slot)) { pkg ->
                            prefs.setMixValue(slot, pkg)
                            rebuild()
                        }
                        else -> rebuild()
                    }""", "mix-addCombo"),
    ("""        if (picked == Action.KEY_COMBO) {
            editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                prefs.setMixValue(slot, v)
                rebuild()
            }
        }""",
     """        when (picked) {
            Action.KEY_COMBO -> editCombo("组合的键盘快捷键", prefs.mixValue(slot)) { v ->
                prefs.setMixValue(slot, v)
                rebuild()
            }
            Action.OPEN_APP -> pickApp("组合 → 打开哪个应用", prefs.mixValue(slot)) { pkg ->
                prefs.setMixValue(slot, pkg)
                rebuild()
            }
            else -> rebuild()
        }""", "mix-editMixKeys"),
], "buttonDetail")

# ---------- ConfigActivity：映射行长按直接换动作（chooseAction 之前没人调用） ----------
patch(C, [
    ("""        row.setOnClickListener {
            startActivity(
                android.content.Intent(this, ButtonDetailActivity::class.java)
                    .putExtra("button", button),
            )
        }""",
     """        row.setOnClickListener {
            startActivity(
                android.content.Intent(this, ButtonDetailActivity::class.java)
                    .putExtra("button", button),
            )
        }
        // 长按：不进去详情页，直接换这个键的动作（更快）
        row.setOnLongClickListener {
            chooseAction(button)
            true
        }""", "longpress"),
], "config")

# ---------- Prefs：导出时排除 profile 自身（避免自我嵌套/覆盖） ----------
patch(P, [
    ("""        for ((k, v) in shared.all) {
            if (!o.has(k)) putRaw(o, k, v)""",
     """        for ((k, v) in shared.all) {
            // profiles / profile_* 是"配置快照"本身，导出会造成自我嵌套与互相覆盖
            if (k == "profiles" || k.startsWith("profile_")) continue
            if (!o.has(k)) putRaw(o, k, v)""", "export-skip-profiles"),
], "prefs")

# ---------- RootInput：restart 时旧线程必须退出，否则两个连线程互相覆盖 socket ----------
patch(R, [
    ("""    fun start() {
        if (running.getAndSet(true)) return
        Thread({ loop() }, "dexpad-link").apply { isDaemon = true }.start()
    }

    private fun loop() {
        while (running.get()) {""",
     """    /** 连接线程的代次：restart 后旧线程看到代次变化就退出，避免两个线程抢 socket */
    @Volatile
    private var linkGen = 0

    fun start() {
        if (running.getAndSet(true)) return
        val gen = ++linkGen
        Thread({ loop(gen) }, "dexpad-link").apply { isDaemon = true }.start()
    }

    private fun loop(gen: Int) {
        while (running.get() && gen == linkGen) {""", "gen-loop"),
    ("""    fun restart() {
        Log.i(TAG, "restarting link")
        running.set(false)""",
     """    fun restart() {
        Log.i(TAG, "restarting link")
        linkGen++          // 让旧线程立刻退出
        running.set(false)""", "gen-restart"),
    ("""                if (running.get()) listener.onLinkLost()""",
     """                if (running.get() && gen == linkGen) listener.onLinkLost()""", "gen-linklost"),
    ("""    private fun readLoop(s: LocalSocket) {
        val reader = BufferedReader(InputStreamReader(s.inputStream))
        while (running.get()) {""",
     """    private fun readLoop(s: LocalSocket) {
        val gen = linkGen
        val reader = BufferedReader(InputStreamReader(s.inputStream))
        while (running.get() && gen == linkGen) {""", "gen-read"),
], "rootInput")

print("FAILS:", fails if fails else "none")
