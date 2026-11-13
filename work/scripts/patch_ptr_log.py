import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()

old = """            val speed = prefs.speedPhone * scale
            if (SystemClock.elapsedRealtime() >= arrowLockUntil) {
                val mx = dx * speed * dtScale
                val my = dy * speed * dtScale
                root.move(mx, my)"""
new = """            val speed = prefs.speedPhone * scale
            if (SystemClock.elapsedRealtime() >= arrowLockUntil) {
                val mx = dx * speed * dtScale
                val my = dy * speed * dtScale
                root.move(mx, my)
                // sampled trail: lets the tests verify sensitivity without
                // reading the system pointer position
                val nowPtr = SystemClock.elapsedRealtime()
                if (nowPtr - lastPtrLogAt > 300) {
                    lastPtrLogAt = nowPtr
                    Log.i(TAG, "ptr move dx=${mx.toInt()} dy=${my.toInt()} sens=${prefs.sensX()}")
                }"""
if old not in s:
    print("MISS"); sys.exit(1)
s = s.replace(old, new, 1)

if "private var lastPtrLogAt" not in s:
    s = s.replace("    private var lastFocusReqAt = 0L",
                  "    private var lastFocusReqAt = 0L\n    private var lastPtrLogAt = 0L", 1)
io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
