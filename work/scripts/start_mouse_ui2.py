import io
root = r"E:\Dennis\GamePadDex复刻\project"

lp = root + r"\app\src\main\res\layout\page_general.xml"
x = io.open(lp, encoding="utf-8").read()
if "switch_start_mouse_mode" not in x:
    i = x.index('android:id="@+id/switch_l3_toggle_enabled"')
    j = x.rfind("<", 0, i)
    add = """<androidx.appcompat.widget.SwitchCompat
        android:id="@+id/switch_start_mouse_mode"
        style="@style/GpmSwitch"
        android:text="@string/start_mouse_mode_title" />

    <TextView
        style="@style/GpmDesc"
        android:text="@string/start_mouse_mode_desc" />

    """
    x = x[:j] + add + x[j:]
    io.open(lp, "w", encoding="utf-8", newline="\n").write(x)
    print("layout ok")

mp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MainActivity.kt"
m = io.open(mp, encoding="utf-8").read()
m = m.replace("""        bindSwitch(R.id.switch_start_mouse_mode, Prefs.START_MOUSE_MODE, true) { checked ->
            if (checked) gpmService?.let { if (!it.mouseMode) it.setMouseModeFromUi(true) }
        }""",
"""        bindSwitch(R.id.switch_start_mouse_mode, Prefs.START_MOUSE_MODE, true) { checked ->
            if (checked) gpmService?.let { if (!it.mouseMode) it.toggleMouseMode(true) }
        }""", 1)
io.open(mp, "w", encoding="utf-8", newline="\n").write(m)
print("binding fixed")