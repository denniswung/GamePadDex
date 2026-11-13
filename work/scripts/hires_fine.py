import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
old = "wheelAcc += (-sy) * (2.0f + 22.0f * scrollMag) * (scrollSpeed / 2f)"
assert old in s, "wheel accumulation not found"
new = "wheelAcc += (-sy) * (1.4f + 11.0f * scrollMag) * (scrollSpeed / 2f)"
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("finest wheel granularity")