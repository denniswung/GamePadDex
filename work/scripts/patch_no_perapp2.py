import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(p, encoding="utf-8").read()

start = s.find("                    // unified gesture: half the task height, 200 ms (fling), and a")
end = s.find('                    if (debugLogs) Log.i(TAG, "vswipe $dy on display $display")', start)
assert start > 0 and end > start
new = '''                    // app-agnostic gesture policy: pull down = one shade pull
                    // from the top edge; push up = one long slow drag repeated
                    // back-to-back so the content keeps moving
                    val down = ny <= 0
                    val dist = if (down) (h * 0.45f).toInt().coerceIn(320, 1200)
                               else (h * 0.35f).toInt().coerceIn(360, 1200)
                    val pct = if (down) 3 else 65
                    val ms = if (down) 200 else 450
                    val dy = if (down) dist else -dist
                    root.swipeV(display, dy, ms, w, h, pct)
                    vSwipeCooldownUntil = now + if (down) swipeRepeatMs() else ms + 40L
'''
s = s[:start] + new + s[end:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("gesture block replaced; topPkg refs:", s.count("topPkg"), "homePkg:", s.count("homePkg"))
