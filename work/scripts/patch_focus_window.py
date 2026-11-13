import io, sys
B = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
E = B + "EngineService.kt"; P = B + "Prefs.kt"; C = B + "ConfigActivity.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# ---- Prefs: focus window ----
rep(P, '        const val KEY_LONG_MS = "long_ms"',
       '        const val KEY_LONG_MS = "long_ms"\n        const val KEY_FOCUS_WINDOW_MS = "focus_window_ms"', "prefs key")

rep(P, "    fun longMs(): Long = shared.getInt(KEY_LONG_MS, 500).coerceIn(300, 1000).toLong()",
"""    fun longMs(): Long = shared.getInt(KEY_LONG_MS, 500).coerceIn(300, 1000).toLong()

    /**
     * How long A keeps acting as "activate focus" after the last d-pad press.
     * Short by design: the user must be able to click again immediately.
     */
    fun focusWindowMs(): Long =
        shared.getInt(KEY_FOCUS_WINDOW_MS, 1200).coerceIn(300, 5000).toLong()""", "prefs focus window")

rep(P, "        o.put(KEY_LONG_MS, longMs().toInt())",
       "        o.put(KEY_LONG_MS, longMs().toInt())\n        o.put(KEY_FOCUS_WINDOW_MS, focusWindowMs().toInt())", "export")

# ---- Engine:有时间窗的 native navigation ----
rep(E, """    /** the system owns navigation right now (d-pad native), A = DPAD_CENTER */
    private var nativeNav = false""",
"""    /** the system owns navigation right now (d-pad native), A = DPAD_CENTER */
    private var nativeNav = false
    /** native navigation expires quickly: A must be a click again right after */
    private var navUntil = 0L""", "field")

rep(E, """    private fun markNativeNav() {
        if (!nativeNav) {""",
"""    /** true while A should activate the focused control instead of clicking */
    private fun navActive(): Boolean =
        nativeNav && SystemClock.elapsedRealtime() < navUntil

    private fun markNativeNav() {
        if (!nativeNav) {""", "navActive")

rep(E, """        nativeNav = true
    }""",
"""        nativeNav = true
        navUntil = SystemClock.elapsedRealtime() + prefs.focusWindowMs()
    }""", "markNativeNav window")

# three consumers
s = io.open(E, encoding="utf-8").read()
s = s.replace("""            Action.LEFT -> {
                if (nativeNav) {
                    // native d-pad navigation: A activates the focused control""",
"""            Action.LEFT -> {
                if (navActive()) {
                    // native d-pad navigation: A activates the focused control""", 1)
s = s.replace("""            Action.LEFT -> {
                if (nativeNav) {
                    // the press was translated into DPAD_CENTER, nothing to release""",
"""            Action.LEFT -> {
                if (navActive()) {
                    // the press was translated into DPAD_CENTER, nothing to release""", 1)
io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("ok consumers")

# expire it in the loop as well
rep(E, """        if (nativeNav && modeOn) {""",
"""        if (nativeNav && !navActive()) {
            nativeNav = false
            Log.i(TAG, "native navigation OFF (window elapsed)")
        }
        if (nativeNav && modeOn) {""", "expire")

# ---- Config UI: slider ----
rep(C, """            sliderRow("边缘减速", 0, 60, prefs.edgeSlow(), "%") { v -> prefs.setEdgeSlow(v) },""",
"""            sliderRow("边缘减速", 0, 60, prefs.edgeSlow(), "%") { v -> prefs.setEdgeSlow(v) },
            sliderRow("方向键焦点窗口", 3, 50, (prefs.focusWindowMs() / 100).toInt(), "00 ms") { v ->
                prefs.setFocusWindowMs(v * 100)
            },""", "ui slider")

rep(P, "    fun setEdgeSlow(v: Int) { shared.edit().putInt(KEY_EDGE_SLOW, v.coerceIn(0, 60)).apply() }",
"""    fun setEdgeSlow(v: Int) { shared.edit().putInt(KEY_EDGE_SLOW, v.coerceIn(0, 60)).apply() }

    fun setFocusWindowMs(v: Int) {
        shared.edit().putInt(KEY_FOCUS_WINDOW_MS, v.coerceIn(300, 5000)).apply()
    }""", "setter")
print("done")
