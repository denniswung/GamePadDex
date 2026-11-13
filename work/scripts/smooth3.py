import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()

# a. the swipe itself becomes a longer, slower drag (less "fling" jitter)
old = """        val stroke = GestureDescription.StrokeDescription(path, 0L, 70L)"""
assert old in s, "stroke duration not found"
new = """        val stroke = GestureDescription.StrokeDescription(path, 0L, 95L)"""
s = s.replace(old, new, 1)

# b. fewer, bigger steps: ~95ms cadence, 25..120 px per stroke
old2 = """                if (now - lastHScrollAt >= 32) {
                    lastHScrollAt = now
                    val sweep = (10f + 45f * scrollMag) * (scrollSpeed / 2f)"""
assert old2 in s
new2 = """                if (now - lastHScrollAt >= 95) {
                    lastHScrollAt = now
                    val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)"""
s = s.replace(old2, new2, 1)

old3 = """                val sweep = (10f + 45f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()"""
assert old3 in s
new3 = """                val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()"""
s = s.replace(old3, new3, 1)

s = s.replace("if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 32) {",
              "if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {", 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("longer strokes, ~95ms cadence")