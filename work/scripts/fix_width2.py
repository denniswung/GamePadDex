import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
if "val width: Int get() = displayWidth" not in s:
    s = s.replace("    private var displayWidth = 1080",
                  "    private var displayWidth = 1080\n    /** read-only view of the display width for the service */\n    val width: Int get() = displayWidth", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("accessor added")