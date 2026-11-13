import io
root = r"E:\Dennis\GamePadDex复刻\project"
cp = root + r"\app\src\main\assets\gpminput.c"
c = io.open(cp, encoding="utf-8").read()
c = c.replace("        case 'H': {\n            int hd = 0;", "        case 'E': {\n            int hd = 0;", 1)
io.open(cp, "w", encoding="utf-8", newline="\n").write(c)
rp = root + r"\app\src\main\java\com\dennis\gamepadmouse\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
r = r.replace('send("H $displayId")', 'send("E $displayId")', 1)
io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
print("E command")