import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
old = """                val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()
                gesture.scroll(ax, ay, -sx, sy, sweep)"""
assert old in s, "vertical gesture not found"
new = """                val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()
                // anchor in the middle of the screen: the cursor may sit in a
                // non-scrollable strip (title bar / category row)
                gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("vertical scroll anchored at the screen centre with a longer sweep")