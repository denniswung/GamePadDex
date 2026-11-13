import io, sys
B = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
P = B + "Prefs.kt"; E = B + "EngineService.kt"

def rep(path, old, new, tag):
    s = io.open(path, encoding="utf-8").read()
    if old not in s:
        print("MISS", tag); sys.exit(1)
    s = s.replace(old, new, 1)
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("ok", tag)

# ---------------- Prefs ----------------
rep(P, "import android.content.SharedPreferences",
"""import android.content.SharedPreferences
import org.json.JSONObject""", "imports")

rep(P, """        fun mixValueKey(i: Int) = "mix_${i}_value\"""",
"""        fun mixValueKey(i: Int) = "mix_${i}_value"

        fun longKey(button: String) = "lng_$button"

        const val KEY_LONG_MS = "long_ms"
        const val KEY_SENS_X = "sens_x"
        const val KEY_SENS_Y = "sens_y"
        const val KEY_EDGE_SLOW = "edge_slow\"""", "keys")

rep(P, """    fun setAction(button: String, action: String) {
        shared.edit().putString(btnKey(button), action).apply()
    }""",
"""    fun setAction(button: String, action: String) {
        shared.edit().putString(btnKey(button), action).apply()
    }

    /** action fired when the button is held longer than [longMs] (通用 §5.1) */
    fun longAction(button: String): String =
        shared.getString(longKey(button), Action.NONE) ?: Action.NONE

    fun setLongAction(button: String, action: String) {
        shared.edit().putString(longKey(button), action).apply()
    }

    fun longMs(): Long = shared.getInt(KEY_LONG_MS, 500).coerceIn(300, 1000).toLong()

    fun sensX(): Float = shared.getInt(KEY_SENS_X, 100).coerceIn(20, 300) / 100f

    fun sensY(): Float = shared.getInt(KEY_SENS_Y, 100).coerceIn(20, 300) / 100f

    fun edgeSlow(): Int = shared.getInt(KEY_EDGE_SLOW, 40).coerceIn(0, 60)

    // ---- import / export / profiles (通用 §5.4) ----
    fun exportJson(): String {
        val o = JSONObject()
        for ((k, v) in shared.all) {
            when (v) {
                is Boolean -> o.put(k, v)
                is Int -> o.put(k, v)
                is Long -> o.put(k, v)
                is Float -> o.put(k, v.toDouble())
                is String -> o.put(k, v)
            }
        }
        o.put("_version", 1)
        return o.toString(2)
    }

    fun importJson(json: String): Boolean {
        return try {
            val o = JSONObject(json)
            val e = shared.edit()
            e.clear()
            for (k in o.keys()) {
                if (k == "_version") continue
                when (val v = o.get(k)) {
                    is Boolean -> e.putBoolean(k, v)
                    is Int -> e.putInt(k, v)
                    is Long -> e.putLong(k, v)
                    is Double -> e.putFloat(k, v.toFloat())
                    is String -> e.putString(k, v)
                }
            }
            e.apply()
            true
        } catch (t: Throwable) {
            false
        }
    }

    fun profiles(): List<String> =
        (shared.getString("profiles", "") ?: "").split(",").filter { it.isNotBlank() }

    fun saveProfile(name: String) {
        val list = profiles().toMutableList()
        if (!list.contains(name)) list.add(name)
        shared.edit()
            .putString("profiles", list.joinToString(","))
            .putString("profile_$name", exportJson())
            .apply()
    }

    fun loadProfile(name: String): Boolean {
        val json = shared.getString("profile_$name", null) ?: return false
        return importJson(json)
    }

    fun deleteProfile(name: String) {
        val list = profiles().filter { it != name }
        shared.edit()
            .putString("profiles", list.joinToString(","))
            .remove("profile_$name")
            .apply()
    }""", "long + io + profiles")

# ---------------- EngineService ----------------
rep(E, """    private val DOUBLE_WINDOW = 320L""",
"""    private val DOUBLE_WINDOW = 320L
    /** press order for combo leader detection (通用 §5.3) */
    private val pressAt = HashMap<String, Long>()
    private val longTimers = HashMap<String, Runnable>()
    private val longFired = HashSet<String>()
    /** estimated pointer position for edge slowdown (reset on L3 centre) */
    private var ptrX = Float.NaN
    private var ptrY = Float.NaN
    private var euroX = OneEuroFilter()
    private var euroY = OneEuroFilter()

    /** One Euro filter (通用 §4.2): low jitter at slow speed, low lag at speed */
    private class OneEuroFilter(
        var minCutoff: Double = 1.0,
        var beta: Double = 0.007,
        var dCutoff: Double = 1.0,
    ) {
        private var xPrev = 0.0
        private var dxPrev = 0.0
        private var first = true

        private fun alpha(cutoff: Double, dt: Double): Double {
            val tau = 1.0 / (2.0 * Math.PI * cutoff)
            return 1.0 / (1.0 + tau / dt)
        }

        fun filter(x: Double, dt: Double): Double {
            if (first) { first = false; xPrev = x; return x }
            val d = (x - xPrev) / dt
            val ad = alpha(dCutoff, dt)
            val dxHat = ad * d + (1 - ad) * dxPrev
            val cutoff = minCutoff + beta * Math.abs(dxHat)
            val a = alpha(cutoff, dt)
            val xHat = a * x + (1 - a) * xPrev
            xPrev = xHat
            dxPrev = dxHat
            return xHat
        }
    }""", "fields")

rep(E, """        if (down) pressedButtons.add(name) else pressedButtons.remove(name)""",
"""        if (down) pressedButtons.add(name) else pressedButtons.remove(name)
        if (down) pressAt[name] = SystemClock.elapsedRealtime() else pressAt.remove(name)
        if (!down) cancelLong(name)""", "pressAt")

rep(E, """            val dbl = prefs.doubleAction(name)
            if (dbl != Action.NONE) {""",
"""            val lng = prefs.longAction(name)
            if (lng != Action.NONE) scheduleLong(name, lng)
            val dbl = prefs.doubleAction(name)
            if (dbl != Action.NONE) {""", "schedule long")

rep(E, """                pendingDowns[name] = cb
                handler.postDelayed(cb, DOUBLE_WINDOW)
                return
            }
            processDown(name)""",
"""                pendingDowns[name] = cb
                handler.postDelayed(cb, DOUBLE_WINDOW)
                return
            }
            if (lng != Action.NONE) {
                // wait for either the long-press timer or the release
                deferredSingles[name] = mappedNow
                return
            }
            processDown(name)""", "long defers single")

rep(E, """                if (pending != null && now - last <= DOUBLE_WINDOW) {
                    handler.removeCallbacks(pending)""",
"""                if (pending != null && now - last <= DOUBLE_WINDOW) {
                    cancelLong(name)
                    handler.removeCallbacks(pending)""", "double cancels long")

rep(E, """    private fun scheduleHold(name: String, mapped: String) {""",
"""    private fun scheduleLong(name: String, action: String) {
        cancelLong(name)
        val r = Runnable {
            longTimers.remove(name)
            if (!pressedButtons.contains(name)) return@Runnable
            if (mixConsumed.contains(name)) return@Runnable
            longFired.add(name)
            pendingDowns.remove(name)?.let { handler.removeCallbacks(it) }
            deferredSingles.remove(name)
            Log.i(TAG, "long $name -> $action")
            if (modeOn && root.helperReady) actions.fire(action, "")
            vibrate(30)
        }
        longTimers[name] = r
        handler.postDelayed(r, prefs.longMs())
    }

    private fun cancelLong(name: String) {
        longTimers.remove(name)?.let { handler.removeCallbacks(it) }
    }

    private fun scheduleHold(name: String, mapped: String) {""", "scheduleLong fn")

rep(E, """            val consumed = mixConsumed.remove(name)
            pendingHolds.remove(name)?.let { handler.removeCallbacks(it) }""",
"""            val consumed = mixConsumed.remove(name)
            val wasLong = longFired.remove(name)
            if (wasLong) {
                pendingHolds.remove(name)?.let { handler.removeCallbacks(it) }
                deferredSingles.remove(name)
            }
            pendingHolds.remove(name)?.let { handler.removeCallbacks(it) }""", "release long")

# combo leader: two-pass fireMix
old_fire = """    private fun fireMix(): Boolean {
        for (i in 0 until Prefs.MIX_COUNT) {
            if (mixFired[i]) continue
            val keys = prefs.mixKeys(i)
            if (keys.size < 2) continue
            val action = prefs.mixAction(i)
            if (action == Action.NONE) continue
            if (keys.any { !pressedButtons.contains(it) }) continue
            // first key wins: if one of the keys is already scrolling, the
            // chord must not steal that press
            if (keys.any { wheelButtons.contains(it) }) continue
            mixFired[i] = true
            for (k in keys) {
                pendingHolds.remove(k)?.let { handler.removeCallbacks(it) }
                deferredSingles.remove(k)
                // also cover buttons whose press handling is still delayed by
                // the double-tap window
                mixConsumed.add(k)
                if (startedHolds.remove(k)) {
                    // a hold-type action already began: stop it
                    releaseActions(k, prefs.action(k))
                }
            }
            Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action")
            fireMixAction(action, prefs.mixValue(i))
            armMixRepeat(action, keys)
            return true
        }
        return false
    }"""
new_fire = """    private fun fireMix(): Boolean {
        // 通用 §5.3: resolve by the actual first-pressed key (leader). Direct
        // configuration wins; a chord configured only in the opposite order is
        // inherited (equivalent key set), so X+A and A+X stay independent.
        fun leaderOf(keys: List<String>): String =
            keys.minByOrNull { pressAt[it] ?: Long.MAX_VALUE } ?: keys.first()

        for (pass in 0..1) {
            for (i in 0 until Prefs.MIX_COUNT) {
                if (mixFired[i]) continue
                val keys = prefs.mixKeys(i)
                if (keys.size < 2) continue
                val action = prefs.mixAction(i)
                if (action == Action.NONE) continue
                if (keys.any { !pressedButtons.contains(it) }) continue
                if (keys.any { wheelButtons.contains(it) }) continue
                val leader = leaderOf(keys)
                val direct = keys.first() == leader
                if (pass == 0 && !direct) continue     // direct pass
                if (pass == 1 && direct) continue      // inherited pass
                mixFired[i] = true
                for (k in keys) {
                    pendingHolds.remove(k)?.let { handler.removeCallbacks(it) }
                    deferredSingles.remove(k)
                    mixConsumed.add(k)
                    if (startedHolds.remove(k)) {
                        releaseActions(k, prefs.action(k))
                    }
                }
                Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action (${if (direct) "direct" else "inherited"})")
                fireMixAction(action, prefs.mixValue(i))
                armMixRepeat(action, keys)
                return true
            }
        }
        return false
    }"""
rep(E, old_fire, new_fire, "fireMix leader")

# lockCenterFor resets the pointer estimate
rep(E, """    override fun lockCenterFor(ms: Long) {""",
"""    override fun lockCenterFor(ms: Long) {
        ptrX = Float.NaN
        ptrY = Float.NaN
        euroX = OneEuroFilter()
        euroY = OneEuroFilter()""", "center resets estimate")

# pointer: sensitivity + one-euro + edge slowdown
rep(E, """        val dead = prefs.deadzone / 1000f
        val dx = curve(axes[0], dead)
        val dy = curve(axes[1], dead)
        if (dx != 0f || dy != 0f) {
            // X + left stick = precision mode: much slower pointer for aiming
            val precision = pressedButtons.contains("x")
            val scale = if (precision) prefs.precisionScale / 100f else 1f
        val speed = prefs.speedPhone * scale
            if (SystemClock.elapsedRealtime() >= arrowLockUntil) {
                root.move(dx * speed * dtScale, dy * speed * dtScale)
            }
        }""",
"""        val dead = prefs.deadzone / 1000f
        val dtSec = (dtScale * 16f / 1000f).toDouble()
        var dx = curve(axes[0] * prefs.sensX(), dead)
        var dy = curve(axes[1] * prefs.sensY(), dead)
        // One Euro: smooths the slow stick, keeps fast flicks responsive
        dx = euroX.filter(dx.toDouble(), dtSec).toFloat()
        dy = euroY.filter(dy.toDouble(), dtSec).toFloat()
        if (dx != 0f || dy != 0f) {
            // X + left stick = precision mode: much slower pointer for aiming
            val precision = pressedButtons.contains("x")
            var scale = if (precision) prefs.precisionScale / 100f else 1f
            // edge slowdown (通用 §4.2): estimated pointer position, re-synced by L3
            val (vw, vh) = displaySize(activeDisplay())
            if (ptrX.isNaN()) { ptrX = vw / 2f; ptrY = vh / 2f }
            val margin = 0.08f
            val nx = (ptrX / vw).coerceIn(0f, 1f)
            val ny = (ptrY / vh).coerceIn(0f, 1f)
            if (prefs.edgeSlow() > 0 &&
                (nx < margin || nx > 1 - margin || ny < margin || ny > 1 - margin)
            ) {
                scale *= 1f - prefs.edgeSlow() / 100f
            }
            val speed = prefs.speedPhone * scale
            if (SystemClock.elapsedRealtime() >= arrowLockUntil) {
                val mx = dx * speed * dtScale
                val my = dy * speed * dtScale
                root.move(mx, my)
                ptrX = (ptrX + mx).coerceIn(0f, vw)
                ptrY = (ptrY + my).coerceIn(0f, vh)
            }
        }""", "pointer filter")
print("done")
