import io, sys
P = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/Prefs.kt"
s = io.open(P, encoding="utf-8").read()

old = """    // ---- import / export / profiles (通用 §5.4) ----
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
    }"""
new = """    // ---- import / export / profiles (通用 §5.4) ----

    /** every stored value (raw map), used as the base of a snapshot */
    private fun putRaw(o: JSONObject, k: String, v: Any?) {
        when (v) {
            is Boolean -> o.put(k, v)
            is Int -> o.put(k, v)
            is Long -> o.put(k, v)
            is Float -> o.put(k, v.toDouble())
            is String -> o.put(k, v)
        }
    }

    /**
     * A complete snapshot: the effective value of every setting (defaults
     * included), so an export can be imported on a fresh install and really
     * restores the configuration.
     */
    fun exportJson(): String {
        val o = JSONObject()
        // scalars (effective values)
        o.put(KEY_ENABLED, enabled)
        o.put(KEY_MODE_ON, modeOn)
        o.put(KEY_SPEED_DEX, speedDex)
        o.put(KEY_SPEED_PHONE, speedPhone)
        o.put(KEY_DEADZONE, deadzone)
        o.put(KEY_SCROLL_DEADZONE, scrollDeadzone)
        o.put(KEY_SCROLL_SPEED, scrollSpeed)
        o.put(KEY_HSWIPE_SPEED, hswipeSpeed)
        o.put(KEY_PRECISION, precisionScale)
        o.put(KEY_INVERT_SCROLL, invertScroll)
        o.put(KEY_VTOUCH, vTouchScroll)
        o.put(KEY_ARROW_MOVE, arrowMovesPointer)
        o.put(KEY_ARROW_STEP, arrowStep)
        o.put(KEY_FORCE_LANDSCAPE, forceLandscape)
        o.put(KEY_WHEEL_SPEED, wheelSpeed)
        o.put(KEY_LONG_MS, longMs().toInt())
        o.put(KEY_SENS_X, (sensX() * 100).toInt())
        o.put(KEY_SENS_Y, (sensY() * 100).toInt())
        o.put(KEY_EDGE_SLOW, edgeSlow())
        o.put(KEY_FOCUS_SCROLL, focusScroll)
        o.put("role_swap", roleSwap)
        // per-button: single / keyboard combo / double / long
        for (b in BUTTONS) {
            o.put(btnKey(b), action(b))
            o.put(comboKey(b), combo(b))
            o.put(doubleKey(b), doubleAction(b))
            o.put(longKey(b), longAction(b))
        }
        // combslots
        for (i in 0 until MIX_COUNT) {
            o.put(mixKeysKey(i), mixKeys(i).joinToString("+"))
            o.put(mixActionKey(i), mixAction(i))
            o.put(mixValueKey(i), mixValue(i))
        }
        // anything else that was stored by hand (unknown keys survive a round trip)
        for ((k, v) in shared.all) {
            if (!o.has(k)) putRaw(o, k, v)
        }
        o.put("_version", 2)
        return o.toString(2)
    }"""
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(s)
print("ok export snapshot")
