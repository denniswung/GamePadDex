import io
root = r"E:\Dennis\GamePadDex复刻\project"
ep = root + r"\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
e = io.open(ep, encoding="utf-8").read()
if "val width: Int get() = displayWidth" not in e:
    e = e.replace("    private var displayWidth = 0",
                  "    private var displayWidth = 0\n    /** current display width, read by the service */\n    val width: Int get() = displayWidth", 1)
    io.open(ep, "w", encoding="utf-8", newline="\n").write(e)
    print("engine width accessor")
sp = root + r"\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
s = s.replace("get() = engine?.displayWidth", "get() = engine?.width", 1)
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service uses accessor")