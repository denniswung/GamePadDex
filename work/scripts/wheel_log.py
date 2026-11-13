import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
if '"wheel "' not in s:
    s = s.replace("                        r.wheel(steps * 120)",
"""                        android.util.Log.i("GpmPointer", "wheel " + (steps * 120) + " dir=" + sy)
                        r.wheel(steps * 120)""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("wheel log added")