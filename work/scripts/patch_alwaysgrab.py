import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

# 1) pref: always grab (block system gamepad input by default)
pp = J + r"\Prefs.kt"
s = io.open(pp, encoding="utf-8").read()
if "pref_always_grab" not in s:
    s = s.replace('    fun rootEnabled() = sp.getBoolean("pref_root_enabled", true)',
'''    fun rootEnabled() = sp.getBoolean("pref_root_enabled", true)

    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */
    fun alwaysGrab() = sp.getBoolean("pref_always_grab", true)''', 1)
    io.open(pp, "w", encoding="utf-8", newline="\n").write(s)
    print("prefs alwaysGrab")

# 2) service: grab on start when the pref says so; only ungrab if the pref is off
sp = J + r"\MouseAccessibilityService.kt"
v = io.open(sp, encoding="utf-8").read()
if "Prefs.alwaysGrab()" not in v:
    v = v.replace("""        pickDisplay()""",
"""        pickDisplay()
        if (Prefs.alwaysGrab() && prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {
            // block the stock gamepad handler even in normal (non mouse) mode
            handler.postDelayed({ root?.grab() }, 800L)
            Log.i(TAG, "always-grab enabled: stock gamepad input is blocked")
        }""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(v)
    print("service alwaysGrab hook")