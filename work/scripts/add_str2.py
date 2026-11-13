import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\res\values\strings_extra.xml"
s = io.open(p, encoding="utf-8").read()
if "start_mouse_mode_title" not in s:
    s = s.replace("</resources>", """    <string name="start_mouse_mode_title">启动即鼠标模式</string>
    <string name="start_mouse_mode_desc">开启后 App 启动（含开机）自动进入鼠标模式；映射一个「切换鼠标模式」按键，就能随时把手柄交还系统打游戏。</string>
</resources>""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("strings added")