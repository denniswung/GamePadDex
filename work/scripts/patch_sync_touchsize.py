import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()

# 1) ready 后同步触摸面尺寸
anchor = 'Log.i(TAG, "hb ready=true'
idx = s.index(anchor)
line_end = s.index("\n", idx)
if "syncTouchSize()" not in s[line_end:line_end + 200]:
    s = s[:line_end + 1] + "        touchSizeSent = \"\"\n        syncTouchSize()\n" + s[line_end + 1:]
    print("ready hook ok")

# 2) step() 里周期性同步
old = "        if (ticks % 125 == 0L && root.helperReady) root.queryTop()"
if old not in s:
    print("MISS step anchor"); sys.exit(1)
if "syncTouchSize()" not in s[s.index(old):s.index(old) + 300]:
    s = s.replace(old, old + "\n        if (ticks % 250 == 0L) syncTouchSize()", 1)
    print("step hook ok")

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("done")
