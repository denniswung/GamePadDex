import io
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 隐藏：不再销毁鼠标设备（那样系统会把光标位置重置，恢复时必然"看得见地修正"），
# 改成把光标一次事件"存"到屏幕外的一个已知停车位。
rep('''    /** 隐藏系统指针：销毁虚拟鼠标设备（没有鼠标设备时系统不画指针） */
    private fun hidePointer() {
        if (pointerHidden || !root.helperReady) return
        root.raw("h")
        pointerHidden = true
        Log.i(TAG, "pointer hidden (mouse device destroyed)")
    }''',
    '''    /** 隐藏指针 = 把光标"停"到屏幕外一个已知坐标（不销毁鼠标设备）。
     *  这样系统的光标位置不会被重置，恢复时可以一次事件回到上次位置，
     *  用户看不到"从角落飞过来"的修正过程。 */
    private fun hidePointer() {
        if (pointerHidden || !root.helperReady) return
        val (vw, vh) = displaySize(activeDisplay())
        val g = prefs.centerGain
        if (ptrX.isNaN()) { ptrX = vw / 2f; ptrY = vh / 2f }
        // 存到屏幕右侧外面（已知停车位）
        val parkX = vw + 300f
        val parkY = if (ptrY.isNaN()) vh / 2f else ptrY.coerceIn(0f, vh.toFloat())
        val rx = (parkX - ptrX) / g
        val ry = (parkY - ptrY) / g
        root.move(rx, ry)
        ptrX = parkX
        ptrY = parkY
        pointerHidden = true
        Log.i(TAG, "pointer parked off-screen ${parkX.toInt()},${parkY.toInt()} (was hidden)")
    }''', "hidePointer")

# 显示：从停车位一次事件回到上次位置
rep('''    /** 恢复指针：重建虚拟鼠标 */
    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false''',
    '''    /** 恢复指针：从屏幕外的停车位，一次事件回到上次位置（用户看到的就是"出现在原地"） */
    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        if (parkedAtX > 0f) {
            val g = prefs.centerGain
            val targetX = (if (lastPosX.isNaN()) 0f else lastPosX).coerceIn(0f, parkedAtX)
            val targetY = (if (lastPosY.isNaN()) 0f else lastPosY)
            root.move((targetX - parkedAtX) / g, (targetY - parkedAtY) / g)
            ptrX = targetX
            ptrY = targetY
            parkedAtX = -1f
            pointerHidden = false
            Log.i(TAG, "pointer restored invisibly at ${targetX.toInt()},${targetY.toInt()}")
            return
        }
        root.raw("j")
        pointerHidden = false''', "showPointer1")

# 记录"上次位置"与停车位
rep("    private var ptrX = Float.NaN\n    private var ptrY = Float.NaN",
    """    private var ptrX = Float.NaN
    private var ptrY = Float.NaN
    /** 隐藏时停车位（-1 = 未停车）与隐藏前的真实位置 */
    private var parkedAtX = -1f
    private var parkedAtY = 0f
    private var lastPosX = Float.NaN
    private var lastPosY = Float.NaN""", "vars")

# 停车前记录 lastPos
rep('''        val parkX = vw + 300f''',
    '''        lastPosX = ptrX
        lastPosY = ptrY
        val parkX = vw + 300f''', "lastpos")

# parkedAt 赋值
rep('''        ptrX = parkX
        ptrY = parkY
        pointerHidden = true''',
    '''        ptrX = parkX
        ptrY = parkY
        parkedAtX = parkX
        parkedAtY = parkY
        pointerHidden = true''', "park-assign")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
