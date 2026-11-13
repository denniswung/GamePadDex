import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()

old = """        // A button whose single action is waiting for release (because it takes
        // part in combos) and that is held while a stick is used is acting as a
        // *modifier* — e.g. X + left stick = precision aiming. Its single action
        // must not fire when it is released afterwards.
        if (deferredSingles.isNotEmpty() &&
            (dx != 0f || dy != 0f || ny != 0f || nx != 0f)
        ) {
            for (k in deferredSingles.keys.toList()) {
                if (mixConsumed.add(k)) {
                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")
                }
            }
            pendingDowns.remove("x")?.let { handler.removeCallbacks(it) }
        }"""
new = """        // 只有「摇杆修饰键」才允许被摇杆运动取消单键动作：
        // X 按住 + 左摇杆 = 慢速指针（这是设计好的），它按下时不该再触发左键。
        // 其它作为组合发起键的按钮（Y、X）不能因为摇杆有位移就丢掉自己的单击动作，
        // 否则「点进应用后马上按 Y 回主屏」会因为摇杆残留/微动而完全没反应。
        if (deferredSingles.isNotEmpty() &&
            (dx != 0f || dy != 0f || ny != 0f || nx != 0f)
        ) {
            for (k in deferredSingles.keys.toList()) {
                if (k !in STICK_MODIFIERS) continue
                if (mixConsumed.add(k)) {
                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")
                }
            }
            if ("x" in STICK_MODIFIERS) {
                pendingDowns.remove("x")?.let { handler.removeCallbacks(it) }
            }
        }"""
if old not in s:
    print("MISS cancel"); sys.exit(1)
s = s.replace(old, new, 1)

anchor = "    private var dpadNative = false"
if anchor not in s:
    print("MISS anchor"); sys.exit(1)
s = s.replace(
    anchor,
    anchor + """
    /** 按下后会被摇杆运动「吞掉」自己单击动作的键（慢速指针修饰键） */
    private val STICK_MODIFIERS = setOf("x")""",
    1,
)
io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
