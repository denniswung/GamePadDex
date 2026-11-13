import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
svc = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse",
                   "MouseAccessibilityService.kt")
eng = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse",
                   "PointerEngine.kt")

s = io.open(svc, encoding="utf-8").read()

# 1) independent horizontal channel driven by the raw right-stick X axis
old_head = """    private fun handleAxis(axis: Int, value: Float) {
        val e = engine ?: return
        Log.i("GpmAxis", "axis=$axis value=$value enabled=${e.enabled}")"""
new_head = """    private fun handleAxis(axis: Int, value: Float) {
        val e = engine ?: return
        Log.i("GpmAxis", "axis=$axis value=$value enabled=${e.enabled}")
        // ---- independent horizontal scroll channel (right stick X) ----
        // The pad may report it as AXIS_Z (no RX/RY pair) or AXIS_RX.
        when (axis) {
            MotionEvent.AXIS_Z, MotionEvent.AXIS_RX, MotionEvent.AXIS_WHEEL, MotionEvent.AXIS_THROTTLE -> {
                val dir = if (Math.abs(value) > 0.35f) (if (value > 0f) -1 else 1) else 0
                if (dir != hScrollDir) {
                    hScrollDir = dir
                    Log.i(TAG, "hscroll raw axis=$axis value=$value -> dir=$dir")
                }
                e.setHScroll(dir)
            }
        }"""
assert old_head in s, "handleAxis head not found"
s = s.replace(old_head, new_head, 1)

# 2) field
s = s.replace("    private var modifierHeld = false",
              "    private var modifierHeld = false\n    private var hScrollDir = 0", 1)

io.open(svc, "w", encoding="utf-8", newline="\n").write(s)
print("service patched")

e = io.open(eng, encoding="utf-8").read()

# 3) PointerEngine: hScroll state + dispatch + logging
e = e.replace("    private var lastHScrollAt = 0L",
              "    private var lastHScrollAt = 0L\n    private var hScrollDir = 0\n    private var hScrollLogged = false", 1)

if "fun setHScroll(" not in e:
    e = e.replace("    fun setScroll(x: Float, y: Float, magnitude: Float = 1f) {",
                  """    /** independent horizontal channel (dir = -1/0/+1) */
    fun setHScroll(dir: Int) {
        hScrollDir = dir
        if (dir == 0) hScrollLogged = false
    }

    fun setScroll(x: Float, y: Float, magnitude: Float = 1f) {""", 1)

dispatch = """    private fun dispatchHScroll(now: Long) {
        if (hScrollDir == 0) return
        if (now - lastHScrollAt < 90) return
        lastHScrollAt = now
        if (!hScrollLogged) {
            hScrollLogged = true
            Log.i(TAG, "HSCROLL dir=$hScrollDir display=${display?.displayId} at ${pos.x},${pos.y}")
        }
        val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
        touchActivity()
        gesture.scroll(pos.x, pos.y, hScrollDir.toFloat(), 0f, sweep)
    }

"""
if "private fun dispatchHScroll" not in e:
    e = e.replace("    private val tick = object : Runnable {", dispatch + "    private val tick = object : Runnable {", 1)

# 4) call it every frame, before the vertical scroll block
anchor = "        // discrete but small & frequent swipes"
if anchor not in e:
    anchor = "        if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 45) {"
assert anchor in e, "vertical scroll anchor not found"
e = e.replace(anchor, "        dispatchHScroll(now)\n\n" + anchor, 1)

io.open(eng, "w", encoding="utf-8", newline="\n").write(e)
print("engine patched")
