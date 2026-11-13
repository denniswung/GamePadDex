import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
old = """            } else {
                // vertical: real ACTION_SCROLL through the root injector
                val dy = -sy * lines
                ok = try { root?.pointScroll(ax, ay, dy, 0f, dispId) ?: false } catch (t: Throwable) { false }
            }
            if (!ok) {
                if (!injectorMissingLogged) {
                    injectorMissingLogged = true
                    android.util.Log.i("GpmPointer", "scroll injector unavailable -> touch swipe fallback")
                }
                if (sx == 0f || sy != 0f) {
                    val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                    gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)
                }
            }"""
assert old in s, "vertical block not found"
new = """            } else {
                // vertical: touch swipe (the injector needs app_process, which the
                // root helper cannot start, so the gesture path is authoritative)
                val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                touchActivity()
                gesture.scroll(ax, ay, -sx, sy, sweep)
                ok = true
            }"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("vertical scroll now uses the touch swipe")