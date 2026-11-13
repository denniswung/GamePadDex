import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
# drop the empty leftover block
s = s.replace("""        if (nativePointer) {
        }
""", "", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("cleaned empty block")