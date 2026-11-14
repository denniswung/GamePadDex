import io

BASE = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/"
R, E = BASE + "RootInput.kt", BASE + "EngineService.kt"
fails = []

r = io.open(R, encoding="utf-8").read()
old_h = '''    fun swipeH(display: Int, dx: Int, ms: Int, maxX: Int, maxY: Int, startPct: Int = -1) {
        if (dx != 0) send("V $display $dx $ms $maxX $maxY $startPct")
    }'''
new_h = '''    fun swipeH(
        display: Int, dx: Int, ms: Int, maxX: Int, maxY: Int, startPct: Int = -1,
        cursorX: Int = -1, cursorY: Int = -1,
    ) {
        if (dx != 0) {
            if (cursorX >= 0 && cursorY >= 0) {
                send("V $display $dx $ms $maxX $maxY $startPct $cursorX $cursorY")
            } else {
                send("V $display $dx $ms $maxX $maxY $startPct")
            }
        }
    }'''
old_v = '''    fun swipeV(display: Int, dy: Int, ms: Int, maxX: Int, maxY: Int, startPct: Int = -1) {
        if (dy != 0) send("Z $display $dy $ms $maxX $maxY $startPct")
    }'''
new_v = '''    fun swipeV(
        display: Int, dy: Int, ms: Int, maxX: Int, maxY: Int, startPct: Int = -1,
        cursorX: Int = -1, cursorY: Int = -1,
    ) {
        if (dy != 0) {
            if (cursorX >= 0 && cursorY >= 0) {
                send("Z $display $dy $ms $maxX $maxY $startPct $cursorX $cursorY")
            } else {
                send("Z $display $dy $ms $maxX $maxY $startPct")
            }
        }
    }'''
for old, new, tag in ((old_h, new_h, "swipeH"), (old_v, new_v, "swipeV")):
    if old not in r:
        fails.append(tag)
    else:
        r = r.replace(old, new, 1)
io.open(R, "w", encoding="utf-8", newline="\n").write(r)

e = io.open(E, encoding="utf-8").read()
reps = [
    ('                    root.swipeV(display, dy, ms, w, h, pct)',
     '                    val (cxp, cyp) = pointerPos()\n                    root.swipeV(display, dy, ms, w, h, pct, cxp.toInt(), cyp.toInt())', "vstick"),
    ('            root.swipeV(display, if (dir > 0) dist else -dist, ms, w, h, -1)',
     '            val (cxp, cyp) = pointerPos()\n            root.swipeV(display, if (dir > 0) dist else -dist, ms, w, h, -1, cxp.toInt(), cyp.toInt())', "vswipe"),
    ('            root.swipeH(display, dir * dist, ms, w, h, -1)',
     '            val (cxp, cyp) = pointerPos()\n            root.swipeH(display, dir * dist, ms, w, h, -1, cxp.toInt(), cyp.toInt())', "hswipe"),
]
for old, new, tag in reps:
    if old not in e:
        fails.append(tag)
    else:
        e = e.replace(old, new, 1)
io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("FAILS:", fails if fails else "none")
