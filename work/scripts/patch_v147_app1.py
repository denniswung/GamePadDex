import io, sys
B = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
R = B + "RootInput.kt"; E = B + "EngineService.kt"; S = B + "EngineState.kt"; P = B + "Prefs.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# ---------------- EngineState ----------------
rep(S, "    @Volatile var lastError: String = \"\"",
"""    @Volatile var lastError: String = ""

    /** helper capability report from `?` (name -> 1/0) */
    @Volatile var caps: Map<String, Int> = emptyMap()

    /** cached scrollable-control rectangle from the accessibility tree */
    @Volatile var focusRect: IntArray? = null

    /** CLOCK_MONOTONIC ms when the helper read the newest key event */
    @Volatile var lastEventMs: Long = 0L

    // ---- input latency (helper read -> action dispatched) ----
    @Volatile var latCount: Int = 0
    @Volatile var latMax: Long = 0L
    @Volatile var latSum: Long = 0L

    fun latReset() {
        latCount = 0
        latMax = 0L
        latSum = 0L
    }

    fun latAdd(ms: Long) {
        if (ms < 0 || ms > 5000) return
        latCount++
        latSum += ms
        if (ms > latMax) latMax = ms
    }""", "engine state")

# ---------------- RootInput fields ----------------
rep(R, """    private val running = AtomicBoolean(false)
    private val devices = ArrayList<String>()""",
"""    private val running = AtomicBoolean(false)
    private val devices = ArrayList<String>()
    private val caps = HashMap<String, Int>()""", "root caps field")

# ---------------- RootInput parse ----------------
rep(R, """            line.startsWith("KEY ") -> {
                val p = line.split(' ')
                if (p.size >= 4) {
                    val linux = p[2].toIntOrNull() ?: return
                    val down = (p[3].toIntOrNull() ?: 0) != 0
                    val android = KeyMap.toAndroid(linux) ?: return
                    listener.onKey(android, if (down) 0 else 1)
                }
            }""",
"""            line.startsWith("KEY ") -> {
                val p = line.split(' ')
                if (p.size >= 4) {
                    val linux = p[2].toIntOrNull() ?: return
                    val down = (p[3].toIntOrNull() ?: 0) != 0
                    if (p.size >= 5) p[4].toLongOrNull()?.let { EngineState.lastEventMs = it }
                    val android = KeyMap.toAndroid(linux) ?: return
                    listener.onKey(android, if (down) 0 else 1)
                }
            }
            line == "SELFTEST begin" -> caps.clear()
            line == "SELFTEST end" -> {
                Log.i(TAG, "selftest " + caps.entries.joinToString(" ") { "${it.key}=${it.value}" })
                EngineState.caps = HashMap(caps)
            }
            line.startsWith("CAP ") -> {
                val p = line.split(' ')
                if (p.size >= 3) p[2].toIntOrNull()?.let { caps[p[1]] = it }
            }
            line.startsWith("FOCUS ") -> {
                val p = line.removePrefix("FOCUS ").trim()
                if (p == "none") {
                    EngineState.focusRect = null
                } else {
                    val parts = p.split(' ')
                    if (parts.size >= 4) {
                        val x1 = parts[0].toIntOrNull()
                        val y1 = parts[1].toIntOrNull()
                        val x2 = parts[2].toIntOrNull()
                        val y2 = parts[3].toIntOrNull()
                        if (x1 != null && y1 != null && x2 != null && y2 != null) {
                            EngineState.focusRect = intArrayOf(x1, y1, x2, y2)
                        }
                    }
                }
            }
            line.startsWith("FOCUS_SET ") || line.startsWith("FOCUS_NONE") ||
                line.startsWith("FOCUS_ANCHOR ") -> Log.i(TAG, "focus: $line")""", "parse caps/focus")

# ---------------- RootInput commands ----------------
rep(R, "    fun move(dx: Float, dy: Float) = send(String.format(Locale.US, \"M %.2f %.2f\", dx, dy))",
"""    /** 链路自检 (通用 §8.1): the helper answers with CAP <name> <0|1> lines */
    fun selftest() = send("?")

    /** refresh the cached scrollable-control rectangle (async, ~2 s) */
    fun focusRefresh() = send("q")

    /** move the pointer into the focused list before a wheel scroll */
    fun focusAnchor() = send("n")

    fun move(dx: Float, dy: Float) = send(String.format(Locale.US, "M %.2f %.2f", dx, dy))""", "root cmds")

# ---------------- Prefs ----------------
rep(P, '        const val KEY_EDGE_SLOW = "edge_slow"',
    '        const val KEY_EDGE_SLOW = "edge_slow"\n        const val KEY_FOCUS_SCROLL = "focus_scroll"', "prefs key")

rep(P, "    fun edgeSlow(): Int = shared.getInt(KEY_EDGE_SLOW, 40).coerceIn(0, 60)",
"""    fun edgeSlow(): Int = shared.getInt(KEY_EDGE_SLOW, 40).coerceIn(0, 60)

    /** scroll/swipe acts on the scrollable control under the pointer (控件级焦点) */
    var focusScroll: Boolean
        get() = shared.getBoolean(KEY_FOCUS_SCROLL, true)
        set(v) = shared.edit().putBoolean(KEY_FOCUS_SCROLL, v).apply()""", "prefs focus")

print("done")
