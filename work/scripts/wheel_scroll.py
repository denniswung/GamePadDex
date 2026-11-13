import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()

# wheel accumulator field
if "wheelAcc" not in s:
    s = s.replace("    private var lastScrollAt = 0L",
                  "    private var lastScrollAt = 0L\n    /** fractional wheel steps, so slow stick movement still scrolls */\n    private var wheelAcc = 0f", 1)

old = """            } else {
                // vertical: touch swipe (the injector needs app_process, which the
                // root helper cannot start, so the gesture path is authoritative)
                val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()
                // anchor in the middle of the screen: the cursor may sit in a
                // non-scrollable strip (title bar / category row)
                gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)
                ok = true
            }"""
assert old in s, "vertical block missing"
new = """            } else {
                // vertical: the SAME channel the left stick uses for the pointer -
                // uinput REL_WHEEL through the root helper. Kernel level events are
                // continuous, so scrolling is as smooth as cursor movement.
                val r = root
                if (r != null && r.isRunning) {
                    wheelAcc += (-sy) * (0.10f + 1.10f * scrollMag) * (scrollSpeed / 2f)
                    val steps = wheelAcc.toInt()
                    if (steps != 0) {
                        wheelAcc -= steps
                        touchActivity()
                        r.wheel(steps)
                    }
                    ok = true
                } else {
                    val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                    touchActivity()
                    gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)
                    ok = true
                }
            }"""
s = s.replace(old, new, 1)
# horizontal keeps the gesture path but is gated with the same cadence
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("vertical scroll now uses uinput REL_WHEEL")