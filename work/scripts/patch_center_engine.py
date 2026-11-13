import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"

e = io.open(E, encoding="utf-8").read()

# 1) 原始单位 -> 像素 的实测增益（uinput REL 单位经系统指针加速后放大约 2.16 倍）
if "RAW_TO_PX" not in e:
    e = e.replace("    private var lastPtrLogAt = 0L",
"""    private var lastPtrLogAt = 0L
    /** uinput REL 单位 → 屏幕像素 的实测增益（指针加速之后约 2.16） */
    private val RAW_TO_PX = 2.16f""", 1)

# 2) 跟踪位置要按真实像素累加（原来按 raw 累加，位置估计整体偏小 2.16 倍）
e = e.replace("""                ptrX = (ptrX + mx).coerceIn(0f, vw.toFloat())
                ptrY = (ptrY + my).coerceIn(0f, vh.toFloat())""",
"""                ptrX = (ptrX + mx * RAW_TO_PX).coerceIn(0f, vw.toFloat())
                ptrY = (ptrY + my * RAW_TO_PX).coerceIn(0f, vh.toFloat())""", 1)

# 3) 真正的一次性居中：按"当前位置 -> 屏幕中心"算一条相对位移，不做夹角、不猜角
if "override fun centerPointer()" not in e:
    anchor = "            override fun onPointerNeeded() {"
    add = """            /** 一次性居中：用引擎自己维护的指针位置，算一条相对位移，
             *  不再"先回角再跳"，因此不会有可见跳变，也不会把指针甩出屏幕。 */
            override fun centerPointer() {
                val (vw, vh) = displaySize(activeDisplay())
                if (ptrX.isNaN()) { ptrX = vw / 2f; ptrY = vh / 2f }
                val dx = (vw / 2f - ptrX) / RAW_TO_PX
                val dy = (vh / 2f - ptrY) / RAW_TO_PX
                if (Math.abs(dx) >= 0.5f || Math.abs(dy) >= 0.5f) root.move(dx, dy)
                ptrX = vw / 2f
                ptrY = vh / 2f
                Log.i(TAG, "center pointer dx=${dx.toInt()} dy=${dy.toInt()} -> ${vw / 2},${vh / 2}")
            }

"""
    e = e.replace(anchor, add + anchor, 1)

io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("engine ok")

a = io.open(A, encoding="utf-8").read()
if "fun centerPointer()" not in a:
    a = a.replace("""        /** the pointer must be visible again (e.g. it was hidden while idle) */
        fun onPointerNeeded()""",
"""        /** the pointer must be visible again (e.g. it was hidden while idle) */
        fun onPointerNeeded()

        /** move the pointer to the middle of the display in ONE relative move */
        fun centerPointer()""", 1)
if "// 一次性居中：用引擎" not in a:
    a = a.replace("""                host.onPointerNeeded()
                val (w, h) = host.displayState().size(display)""",
"""                host.onPointerNeeded()
                host.centerPointer()
                val (w, h) = host.displayState().size(display)""", 1)
    a = a.replace("""                host.lockCenterFor(3000)
                root.centerCursor(w, h, host.isPhone(), rot)""",
"""                host.lockCenterFor(300)
                // 位移已由 centerPointer() 一步完成，这里不再用助手的"夹角"算法""", 1)
io.open(A, "w", encoding="utf-8", newline="\n").write(a)
print("router ok")
