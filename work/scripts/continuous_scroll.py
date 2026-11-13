import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()

# 1) strokes live 60ms each and are extended every ~40ms (time driven, no callbacks)
s = s.replace("val s = GestureDescription.StrokeDescription(path, 0L, 40L, true)",
              "val s = GestureDescription.StrokeDescription(path, 0L, 60L, true)", 1)
s = s.replace("val next = s.continueStroke(path, 0L, 40L, true)",
              "val next = s.continueStroke(path, 0L, 60L, true)", 1)

# 2) continuous scroll driver
helper = '''
    // ------------------------------------------------ continuous scroll drag
    private var scrollDragActive = false
    private var scrollAccX = 0f
    private var scrollAccY = 0f
    private var lastDragStepAt = 0L

    /**
     * One long touch drag that keeps being extended while the stick is held.
     * Driving it from the frame timer (instead of waiting for gesture callbacks,
     * which are unreliable on this device) removes the "many tiny flings" jitter
     * of the discrete swipe approach.
     */
    private fun continuousScroll(now: Long, sx: Float, sy: Float) {
        val active = sx != 0f || sy != 0f
        if (!active) {
            if (scrollDragActive) {
                gesture.endScrollDrag(displayWidth / 2f + scrollAccX, displayHeight / 2f + scrollAccY)
                scrollDragActive = false
            }
            return
        }
        val cx = displayWidth / 2f
        val cy = displayHeight / 2f
        if (!scrollDragActive) {
            scrollAccX = 0f
            scrollAccY = 0f
            scrollDragActive = true
            lastDragStepAt = now
            touchActivity()
            gesture.startScrollDrag(cx, cy)
            return
        }
        if (now - lastDragStepAt < 40) return
        lastDragStepAt = now
        val stepPx = (5f + 22f * scrollMag) * (scrollSpeed / 2f)
        scrollAccX += -sx * stepPx
        scrollAccY += sy * stepPx
        // keep the drag inside the display
        scrollAccX = scrollAccX.coerceIn(-cx * 0.8f, cx * 0.8f)
        scrollAccY = scrollAccY.coerceIn(-cy * 0.8f, cy * 0.8f)
        touchActivity()
        gesture.continueScrollDrag(cx + scrollAccX, cy + scrollAccY)
    }

'''
anchor = "    private val tick = object : Runnable {"
assert anchor in s, "tick anchor missing"
s = s.replace(anchor, helper + anchor, 1)

# 3) call it every frame, right after sx/sy are known, and disable the old path
old = """        val sx = scrollDirX
        val sy = scrollDirY"""
assert old in s, "sx/sy block missing"
new = """        val sx = scrollDirX
        val sy = scrollDirY
        continuousScroll(now, sx, sy)"""
s = s.replace(old, new, 1)

# the discrete block no longer runs
s = s.replace("if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {",
              "if (false && (sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("continuous drag scroll wired")