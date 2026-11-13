import io
root = r"E:\Dennis\GamePadDex复刻\project"
svc = root + r"\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(svc, encoding="utf-8").read()
if "fun applyAlwaysGrab" not in s:
    s = s.replace("    /** entry point for debug broadcasts / other components */",
"""    /** apply the "block stock gamepad input" preference right away */
    fun applyAlwaysGrab(checked: Boolean) {
        if (checked) root?.grab() else if (!mouseMode) root?.ungrab()
    }

    /** entry point for debug broadcasts / other components */""", 1)
    io.open(svc, "w", encoding="utf-8", newline="\n").write(s)
    print("service helper added")

mp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MainActivity.kt"
m = io.open(mp, encoding="utf-8").read()
m = m.replace("""            runCatching {
                val svc = gpmService
                if (checked) svc?.root?.grab() else if (svc?.mouseMode != true) svc?.root?.ungrab()
            }""",
"""            runCatching { gpmService?.applyAlwaysGrab(checked) }""", 1)
io.open(mp, "w", encoding="utf-8", newline="\n").write(m)
print("mainactivity fixed")