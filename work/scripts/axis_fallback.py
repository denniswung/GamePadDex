import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
old = """            else -> {
                // no clear direction yet: do not scroll at all
                e.setScroll(0f, 0f, 0f)
                return
            }"""
assert old in s, "else branch not found"
new = """            else -> {
                // no clear winner yet: fall back to the dominant axis so scrolling
                // never dies completely (the stick may be pushed off-centre)
                if (Math.abs(x) >= Math.abs(y)) {
                    ux = if (x > 0f) 1f else -1f
                    uy = 0f
                } else {
                    ux = 0f
                    uy = if (y > 0f) 1f else -1f
                }
            }"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("dominant-axis fallback instead of dead zone")