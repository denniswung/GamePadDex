import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\Prefs.kt"
s = io.open(p, encoding="utf-8").read()
s = s.replace('''    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */
    fun alwaysGrab() = sp.getBoolean(ALWAYS_GRAB, true)''',
'''    /** keep the gamepad grabbed even when mouse mode is off (block stock input) */
    fun alwaysGrab(p: SharedPreferences) = p.getBoolean(ALWAYS_GRAB, true)''', 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
q = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
t = io.open(q, encoding="utf-8").read()
t = t.replace("if (Prefs.alwaysGrab() && prefs.getBoolean(Prefs.ROOT_ENABLED, true))",
              "if (Prefs.alwaysGrab(prefs) && prefs.getBoolean(Prefs.ROOT_ENABLED, true))", 1)
io.open(q, "w", encoding="utf-8", newline="\n").write(t)
print("signature fixed")