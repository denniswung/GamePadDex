import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\Prefs.kt"
s = io.open(p, encoding="utf-8").read()
if "fun alwaysGrab()" not in s:
    s = s.replace('    const val ROOT_ENABLED = "pref_root_enabled"                   // boolean, true',
'''    const val ROOT_ENABLED = "pref_root_enabled"                   // boolean, true
    const val ALWAYS_GRAB = "pref_always_grab"                     // boolean, true

    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */
    fun alwaysGrab() = sp.getBoolean(ALWAYS_GRAB, true)''', 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("alwaysGrab added")