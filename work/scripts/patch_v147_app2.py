import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

def rep(old, new, tag):
    s = io.open(E, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(E, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# ---- 1. latency on keys ----
rep("""    override fun onKey(keyCode: Int, action: Int) {
        val name = KeyMap.buttonName(keyCode) ?: return
        handleButton(name, action == 0)
    }""",
"""    override fun onKey(keyCode: Int, action: Int) {
        val name = KeyMap.buttonName(keyCode) ?: return
        val stamp = EngineState.lastEventMs
        handleButton(name, action == 0)
        // helper read -> action dispatched (both clocks are CLOCK_MONOTONIC)
        if (stamp > 0) EngineState.latAdd(System.nanoTime() / 1_000_000 - stamp)
    }""", "onKey latency")

# ---- 2. selftest on ready ----
rep("""    override fun onReady() {""",
"""    override fun onReady() {
        // 链路自检: report missing root capabilities instead of failing silently
        root.selftest()""", "onReady selftest")

# ---- 3. focus refresh + wheel anchor in step() ----
rep("""        val scrollDead = prefs.scrollDeadzone / 1000f
        var sy = axes[13]                       // AXIS_RY""",
"""        val scrollDead = prefs.scrollDeadzone / 1000f
        var sy = axes[13]                       // AXIS_RY""", "noop")

rep("""        val ny = scrollCurve(sy, scrollDead)
        if (prefs.vTouchScroll) {""",
"""        val ny = scrollCurve(sy, scrollDead)
        // 控件级焦点: keep the scrollable-control rectangle fresh while the
        // right stick is scrolling (the helper dumps at most every 5 s)
        if (prefs.focusScroll && ny != 0f && nowMs - lastFocusReqAt > 2000) {
            lastFocusReqAt = nowMs
            root.focusRefresh()
        }
        if (!prefs.vTouchScroll && ny != 0f && !wheelAnchored) {
            wheelAnchored = true
            root.focusAnchor()
        } else if (ny == 0f) {
            wheelAnchored = false
        }
        if (prefs.vTouchScroll) {""", "focus refresh")

# nowMs local: step() has nowMs defined
rep("""        val nowMs = SystemClock.elapsedRealtime()""",
"""        val nowMs = SystemClock.elapsedRealtime()""", "noop2")

# ---- 4. fields ----
rep("""    private var mixHoldNextAt = 0L""",
"""    private var mixHoldNextAt = 0L
    /** 控件级焦点: throttle for the async accessibility query */
    private var lastFocusReqAt = 0L
    private var wheelAnchored = false""", "fields")

# ---- 5. heartbeat: latency + caps ----
rep("""        if (ticks % 625 == 0L) {
            Log.i(TAG, "hb ready=${root.helperReady} silent=${SystemClock.elapsedRealtime() - root.lastLineAt}ms")
        }""",
"""        if (ticks % 625 == 0L) {
            Log.i(TAG, "hb ready=${root.helperReady} silent=${SystemClock.elapsedRealtime() - root.lastLineAt}ms")
            val n = EngineState.latCount
            if (n > 0) {
                Log.i(TAG, "lat n=$n avg=${EngineState.latSum / n}ms max=${EngineState.latMax}ms")
                EngineState.latReset()
            }
            val caps = EngineState.caps
            if (caps.isNotEmpty()) {
                val bad = caps.filter { it.value == 0 }.keys
                if (bad.isNotEmpty()) Log.w(TAG, "cap missing: ${bad.joinToString(",")}")
            }
        }""", "hb latency")

print("done")
