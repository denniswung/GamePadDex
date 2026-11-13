import io
root = r"E:\Dennis\GamePadDex复刻\project"

# 1) layout: add the switch right after the root-enabled switch + desc
lp = root + r"\app\src\main\res\layout\page_root_dex.xml"
x = io.open(lp, encoding="utf-8").read()
if "switch_always_grab" not in x:
    anchor = """    <TextView
        style="@style/GpmDesc"
        android:text="@string/root_own_gamepad_desc" />
"""
    add = anchor + """
    <androidx.appcompat.widget.SwitchCompat
        android:id="@+id/switch_always_grab"
        style="@style/GpmSwitch"
        android:text="@string/always_grab_title" />

    <TextView
        style="@style/GpmDesc"
        android:text="@string/always_grab_desc" />
"""
    assert anchor in x, "root_own_gamepad_desc block missing"
    x = x.replace(anchor, add, 1)
    io.open(lp, "w", encoding="utf-8", newline="\n").write(x)
    print("layout ok")

# 2) strings
sp = root + r"\app\src\main\res\values\strings_extra.xml"
s = io.open(sp, encoding="utf-8").read()
if "always_grab_title" not in s:
    s = s.replace("</resources>", """    <string name="always_grab_title">默认屏蔽系统输入</string>
    <string name="always_grab_desc">开启后，助手一启动就独占手柄（EVIOCGRAB），三星/DeX 的自带手柄处理不会再收到输入；关闭后只有鼠标模式开启时才独占。</string>
</resources>""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("strings ok")

# 3) MainActivity: bind the switch
mp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MainActivity.kt"
m = io.open(mp, encoding="utf-8").read()
if "switch_always_grab" not in m:
    bind = '''
    private fun bindAlwaysGrab() {
        val sw = findViewById<androidx.appcompat.widget.SwitchCompat>(R.id.switch_always_grab)
        if (sw == null) return
        sw.isChecked = Prefs.alwaysGrab(prefs)
        sw.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean(Prefs.ALWAYS_GRAB, checked).apply()
            // apply immediately: grab now, or release if mouse mode is off
            runCatching {
                val svc = gpmService
                if (checked) svc?.root?.grab() else if (svc?.mouseMode != true) svc?.root?.ungrab()
            }
        }
    }

'''
    m = m.replace("    private fun bindMappingPage() {", bind + "    private fun bindMappingPage() {", 1)
    m = m.replace("    private fun bindMappingPage() {\n        bindFullKeyMapping()",
                  "    private fun bindMappingPage() {\n        bindFullKeyMapping()\n        bindAlwaysGrab()", 1)
    io.open(mp, "w", encoding="utf-8", newline="\n").write(m)
    print("mainactivity ok")