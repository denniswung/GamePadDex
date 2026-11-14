import io, re
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()
fails = []


def rep(old, new, tag):
    global s
    if old not in s:
        fails.append(tag)
        return
    s = s.replace(old, new, 1)


# 隐藏：恢复成"销毁鼠标设备"（瞬间消失，最干净）
start = s.index("    /** 隐藏指针 = 把光标\"停\"到屏幕外一个已知坐标（不销毁鼠标设备）。")
end = s.index("    /** 恢复指针", start)
s = s[:start] + '''    /** 隐藏指针：销毁虚拟鼠标设备（系统不画指针，瞬间消失） */
    private fun hidePointer() {
        if (pointerHidden || !root.helperReady) return
        root.raw("h")
        pointerHidden = true
        Log.i(TAG, "pointer hidden (device destroyed)")
    }

''' + s[end:]

# 显示：只重建设备，不做任何"修正移动"。
# 实测：鼠标设备销毁再重建后，系统会保留光标坐标 → 光标直接就出现在上次的位置（隐形修正）。
start = s.index("    /** 恢复指针：从屏幕外的停车位")
end = s.index("    /** 调试/测试用", start)
s = s[:start] + '''    /** 恢复指针：只重建设备。系统会保留光标坐标，所以光标直接出现在上次位置，
     *  没有任何可见的"修正移动"（这就是"隐形修正"）。 */
    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false
        Log.i(TAG, "pointer shown at last position (no correction move)")
    }

''' + s[end:]

# onReady 也不做修正（位置由系统保留）
rep('''        runCatching {
            val display = activeDisplay()
            val (vw, vh) = displaySize(display)
            val tx = (if (ptrX.isNaN()) vw / 2f else ptrX).coerceIn(0f, vw.toFloat())
            val ty = (if (ptrY.isNaN()) vh / 2f else ptrY).coerceIn(0f, vh.toFloat())
            root.positionPointer(tx.toInt(), ty.toInt(), vw, vh)
            ptrX = tx
            ptrY = ty
            centerLock = true
            centerLockUntil = SystemClock.elapsedRealtime() + 260
            Log.i(TAG, "helper ready: pointer restored at ${tx.toInt()},${ty.toInt()}")
        }''',
    '''        Log.i(TAG, "helper ready: pointer device recreated (system keeps the position)")''', "onReady")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
