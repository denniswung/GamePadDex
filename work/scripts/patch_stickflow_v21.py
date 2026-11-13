import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/v2/StickFlow.kt"
s = io.open(p, encoding="utf-8").read()

s = s.replace("""        fun wheel(steps: Int, horizontal: Boolean)
        fun anchorForWheel()
        fun log(msg: String)""",
"""        fun wheel(steps: Int, horizontal: Boolean)
        fun anchorForWheel()
        fun log(msg: String)

        /** true when the stick starts/stops driving scroll output */
        fun onScrollActivity(active: Boolean)""")

s = s.replace("""    private var inertiaVx = 0f
    private var inertiaNextAt = 0L
    private var inertiaTicks = 0""",
"""    private var inertiaVx = 0f
    private var inertiaNextAt = 0L
    private var inertiaTicks = 0

    /** X-as-modifier slow pointer */
    var slowPointerScale = 1f
    /** pointer lock after L3 centre */
    private var centerLockUntil = 0L
    private var centerNeedsNeutral = false
    /** scroll suppression while a key-scroll action is active */
    private var suppressScrollUntil = 0L
    private var scrollActive = false
    /** virtual pointer position, used for edge slowdown */
    private var vx = Float.NaN
    private var vy = Float.NaN
    private var viewW = 2560f
    private var viewH = 1600f""")

s = s.replace("""    fun tick(now: Long) {
        flx = filtered(flx, lx); fly = filtered(fly, ly)
        frx = filtered(frx, rx); fry = filtered(fry, ry)""",
"""    fun centerLock(ms: Long) {
        centerLockUntil = SystemClock.elapsedRealtime() + ms
        centerNeedsNeutral = true
    }

    fun suppressFor(ms: Long) {
        suppressScrollUntil = SystemClock.elapsedRealtime() + ms
        stopOutput()
    }

    fun setViewport(w: Int, h: Int) {
        viewW = w.toFloat().coerceAtLeast(1f)
        viewH = h.toFloat().coerceAtLeast(1f)
        if (vx.isNaN()) { vx = viewW / 2f; vy = viewH / 2f }
    }

    fun tick(now: Long) {
        flx = filtered(flx, lx); fly = filtered(fly, ly)
        frx = filtered(frx, rx); fry = filtered(fry, ry)""")

s = s.replace("""        val pMag = hypot(pointerX.toDouble(), pointerY.toDouble()).toFloat()
        val dz = cfg.deadzone
        if (pMag > dz) {
            val shaped = shape(pMag, dz)
            val basePx = 30f * cfg.cursorSpeed
            val dx = pointerX / pMag * shaped * basePx
            val dy = pointerY / pMag * shaped * basePx
            host.movePointer(dx, dy)
        }""",
"""        val pMag = hypot(pointerX.toDouble(), pointerY.toDouble()).toFloat()
        val dz = cfg.deadzone
        var pointerAllowed = true
        if (now < centerLockUntil) {
            pointerAllowed = false
        } else if (centerNeedsNeutral) {
            if (pMag <= dz) centerNeedsNeutral = false else pointerAllowed = false
        }
        if (pMag > dz && pointerAllowed) {
            val shaped = shape(pMag, dz)
            var scale = cfg.cursorSpeed * slowPointerScale
            // edge slowdown: estimate the pointer position from accumulated moves
            if (cfg.edgeSlow > 0) {
                val margin = 0.08f
                val nx = (vx / viewW).coerceIn(0f, 1f)
                val ny = (vy / viewH).coerceIn(0f, 1f)
                val nearEdge = nx < margin || nx > 1 - margin || ny < margin || ny > 1 - margin
                if (nearEdge) scale *= 1f - cfg.edgeSlow / 100f
            }
            val basePx = 30f * scale
            var dx = pointerX / pMag * shaped * basePx
            var dy = pointerY / pMag * shaped * basePx
            if (!vx.isNaN()) {
                val beforeX = vx
                val beforeY = vy
                vx = (vx + dx).coerceIn(0f, viewW)
                vy = (vy + dy).coerceIn(0f, viewH)
                dx = vx - beforeX
                dy = vy - beforeY
            }
            if (dx != 0f || dy != 0f) host.movePointer(dx, dy)
        }""")

s = s.replace("""        val sMag = hypot(sx.toDouble(), sy.toDouble()).toFloat()

        if (sMag > dz) {""",
"""        val sMag = hypot(sx.toDouble(), sy.toDouble()).toFloat()
        val scrollSuppressed = now < suppressScrollUntil

        if (sMag > dz && !scrollSuppressed) {""")

s = s.replace("""            if (!pulseActive) {
                pulseActive = true""",
"""            if (!pulseActive) {
                pulseActive = true
                if (!scrollActive) { scrollActive = true; host.onScrollActivity(true) }""")

s = s.replace("""            if (pulseActive) {
                pulseActive = false
                if (locked == Axis.X && cfg.inertia < 0.999f) {""",
"""            if (pulseActive) {
                pulseActive = false
                if (scrollActive) { scrollActive = false; host.onScrollActivity(false) }
                if (locked == Axis.X && cfg.inertia < 0.999f) {""")

s = s.replace("""        } else {
            if (pulseActive) {""", """        } else {
            if (pulseActive) {""")

s = s.replace("""        // ---- horizontal inertia (wheel backend only) ----
        if (inertiaTicks > 0 && now >= inertiaNextAt && cfg.outputMode == "wheel") {
            host.wheel((inertiaVx * 2).toInt().let { if (it == 0) (if (inertiaVx > 0) 1 else -1) else it }, true)
            inertiaVx *= cfg.inertia
            inertiaTicks--
            inertiaNextAt = now + 40L
        }""",
"""        // ---- horizontal inertia (both backends) ----
        if (inertiaTicks > 0 && now >= inertiaNextAt) {
            if (cfg.outputMode == "wheel") {
                host.wheel((inertiaVx * 2).toInt().let { if (it == 0) (if (inertiaVx > 0) 1 else -1) else it }, true)
            } else {
                val dist = (viewW * 0.08f * inertiaVx).toInt()
                if (dist != 0) host.swipe(false, if (inertiaVx > 0) 1 else -1, 8, -1)
            }
            inertiaVx *= cfg.inertia
            inertiaTicks--
            inertiaNextAt = now + 40L
        }""")

s = s.replace("""    fun stopOutput() {
        pulseActive = false
        inertiaTicks = 0
        inertiaVx = 0f
    }""",
"""    fun stopOutput() {
        pulseActive = false
        inertiaTicks = 0
        inertiaVx = 0f
        if (scrollActive) { scrollActive = false; host.onScrollActivity(false) }
    }""")

io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("stickflow patched")
