import io
root = r"E:\Dennis\GamePadDex复刻\project"

# layout: add the switch right after the mouse-service switch block
lp = root + r"\app\src\main\res\layout\page_general.xml"
x = io.open(lp, encoding="utf-8").read()
if "switch_start_mouse_mode" not in x:
    anchor = 'android:id="@+id/switch_mouse_enabled"'
    i = x.index(anchor)
    # insert after the closing of that SwitchCompat and its description TextView
    j = x.index("/>", i) + 2
    k = x.index("</TextView>", j) + len("</TextView>")
    add = """

    <androidx.appcompat.widget.SwitchCompat
        android:id="@+id/switch_start_mouse_mode"
        style="@style/GpmSwitch"
        android:text="@string/start_mouse_mode_title" />

    <TextView
        style="@style/GpmDesc"
        android:text="@string/start_mouse_mode_desc" />"""
    x = x[:k] + add + x[k:]
    io.open(lp, "w", encoding="utf-8", newline="\n").write(x)
    print("layout ok")

# strings
sp = root + r"\app\src\main\res\values\strings_extra.xml"
s = io.open(sp, encoding="utf-8").read()
if "start_mouse_mode_title" not in s:
    s = s.replace("</resources>", """    <string name="start_mouse_mode_title">启动即鼠标模式</string>
    <string name="start_mouse_mode_desc">开启后，App 启动（含开机）自动进入鼠标模式；映射一个「切换鼠标模式」按键即可临时把手柄交还系统打游戏。</string>
</resources>""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("strings ok")

# binding
mp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MainActivity.kt"
m = io.open(mp, encoding="utf-8").read()
if "switch_start_mouse_mode" not in m:
    m = m.replace("        bindSwitch(R.id.switch_haptic_feedback, Prefs.HAPTIC, true)",
                  "        bindSwitch(R.id.switch_haptic_feedback, Prefs.HAPTIC, true)\n        bindSwitch(R.id.switch_start_mouse_mode, Prefs.START_MOUSE_MODE, true) { checked ->\n            if (checked) gpmService?.let { if (!it.mouseMode) it.setMouseModeFromUi(true) }\n        }", 1)
    io.open(mp, "w", encoding="utf-8", newline="\n").write(m)
    print("binding ok")