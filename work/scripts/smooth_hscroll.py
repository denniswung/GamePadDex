import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
old = """            if (horizontal) {
                // Android apps almost never handle AXIS_HSCROLL, so horizontal
                // scrolling goes through a real touch swipe instead
                if (now - lastHScrollAt >= 90) {
                    lastHScrollAt = now
                    val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
                    gesture.scroll(ax, ay, sx, 0f, sweep)
                }
                ok = true"""
assert old in s, "horizontal block not found"
new = """            if (horizontal) {
                // Android apps almost never handle AXIS_HSCROLL, so horizontal
                // scrolling goes through a real touch swipe instead; use the same
                // small & frequent steps as the vertical path for a smooth feel
                if (now - lastHScrollAt >= 32) {
                    lastHScrollAt = now
                    val sweep = (10f + 45f * scrollMag) * (scrollSpeed / 2f)
                    touchActivity()
                    gesture.scroll(displayWidth / 2f, displayHeight / 2f, sx, 0f, sweep)
                }
                ok = true"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("horizontal uses the same smooth cadence")