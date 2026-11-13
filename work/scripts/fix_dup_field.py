import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
lines = io.open(p, encoding="utf-8").read().split("\n")
# drop the older duplicate field (line 98, 0-based 97)
assert "scrollDragActive" in lines[97], lines[97]
del lines[97]
io.open(p, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print("duplicate field removed")