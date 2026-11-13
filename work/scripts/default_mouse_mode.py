import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

# 1) pref: start in mouse mode
pp = J + r"\Prefs.kt"
s = io.open(pp, encoding="utf-8").read()
if "START_MOUSE_MODE" not in s:
    s = s.replace('    const val ROOT_ENABLED = "pref_root_enabled"                   // boolean, true',
'''    const val ROOT_ENABLED = "pref_root_enabled"                   // boolean, true
    const val START_MOUSE_MODE = "pref_start_mouse_mode"           // boolean, true''', 1)
    s = s.replace("    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */",
'''    /** boot into mouse mode; a mapped button switches to system mode */
    fun startMouseMode(p: SharedPreferences) = p.getBoolean(START_MOUSE_MODE, true)

    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */''', 1)
    io.open(pp, "w", encoding="utf-8", newline="\n").write(s)
    print("prefs ok")

# 2) service: enable mouse mode on start, and re-arm when the pad reconnects
sp = J + r"\MouseAccessibilityService.kt"
v = io.open(sp, encoding="utf-8").read()
if "startMouseMode(prefs)" not in v:
    v = v.replace("""        if (Prefs.alwaysGrab(prefs) && prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {""",
"""        if (Prefs.startMouseMode(prefs)) {
            // default: the pad drives our pointer; a mapped button hands it back
            handler.postDelayed({
                if (!mouseMode) {
                    toggleMouseMode(true)
                    Log.i(TAG, "auto-entered mouse mode on service start")
                }
            }, 1500L)
        }
        if (Prefs.alwaysGrab(prefs) && prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(v)
    print("service auto mouse mode")