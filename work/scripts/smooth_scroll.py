import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
# smaller, more frequent swipes -> smooth instead of steppy
old = """                val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()
                // anchor in the middle of the screen: the cursor may sit in a
                // non-scrollable strip (title bar / category row)
                gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)"""
assert old in s, "vertical scroll block"
new = """                val sweep = (10f + 45f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()
                // anchor in the middle of the screen: the cursor may sit in a
                // non-scrollable strip (title bar / category row)
                gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)"""
s = s.replace(old, new, 1)
# faster cadence: 45ms -> 32ms
s = s.replace("if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 45) {",
              "if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 32) {", 1)
s = s.replace("if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 70) {",
              "if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 32) {", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("smoother scrolling: 32ms cadence, 10..55 px steps")