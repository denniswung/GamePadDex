import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()

# state field
if "scrollAxisLock" not in s:
    s = s.replace("    private var hScrollDir = 0",
                  "    private var hScrollDir = 0\n    /** 0 = unlocked, 1 = horizontal locked, -1 = vertical locked */\n    private var scrollAxisLock = 0", 1)

old = """        // axis lock: a tiny off-axis component must not steal the gesture, so we
        // pick one axis at a time (1.2x dominance) - this is what makes left/right
        // scrolling reachable instead of always registering as up/down
        var ux = x / hypot
        var uy = y / hypot
        val ax = Math.abs(ux)
        val ay = Math.abs(uy)
        if (ax > ay * 1.2f) {
            uy = 0f
            ux = if (ux > 0f) 1f else -1f
        } else if (ay > ax * 1.2f) {
            ux = 0f
            uy = if (uy > 0f) 1f else -1f
        } else {
            // genuinely diagonal: keep both but damp the weaker one
            if (ax < ay) ux *= 0.5f else uy *= 0.5f
        }"""
assert old in s, "axis lock block not found"
new = """        // ---- axis lock with hysteresis (prevents accidental vertical trigger) ----
        //  * a lock is only taken when one axis clearly dominates (1.6x) AND the
        //    deflection is beyond the activation threshold
        //  * once locked, the other axis is forced to zero until the stick comes
        //    back near centre - so a horizontal swipe can never drift into a
        //    vertical scroll halfway through
        var ux = x / hypot
        var uy = y / hypot
        val ax = Math.abs(ux)
        val ay = Math.abs(uy)
        val lockThreshold = 0.35f          // minimum deflection to start scrolling
        val dominance = 1.6f               // how clearly one axis must win
        if (scrollAxisLock == 1) {
            if (ax < 0.25f || ay > ax * 0.9f) scrollAxisLock = 0
        } else if (scrollAxisLock == -1) {
            if (ay < 0.25f || ax > ay * 0.9f) scrollAxisLock = 0
        }
        if (scrollAxisLock == 0 && hypot >= lockThreshold) {
            when {
                ax > ay * dominance -> scrollAxisLock = 1
                ay > ax * dominance -> scrollAxisLock = -1
            }
        }
        when (scrollAxisLock) {
            1 -> {
                ux = if (x > 0f) 1f else -1f
                uy = 0f
            }
            -1 -> {
                uy = if (y > 0f) 1f else -1f
                ux = 0f
            }
            else -> {
                // no clear direction yet: do not scroll at all
                e.setScroll(0f, 0f, 0f)
                return
            }
        }"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("axis lock with hysteresis installed")