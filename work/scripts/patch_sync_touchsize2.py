import io
C = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ConfigActivity.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

c = io.open(C, encoding="utf-8").read()
if "import android.content.Intent" not in c:
    c = c.replace("import android.content.res.ColorStateList",
                  "import android.content.Intent\nimport android.content.res.ColorStateList", 1)
    io.open(C, "w", encoding="utf-8", newline="\n").write(c)
    print("config import ok")

e = io.open(E, encoding="utf-8").read()
old = 'Log.i(TAG, "hb ready=${root.helperReady} silent=${SystemClock.elapsedRealtime() - root.lastLineAt}ms")'
if old not in e:
    print("MISS ready log")
else:
    if "syncTouchSize()" not in e:
        e = e.replace(old, old + "\n        touchSizeSent = \"\"\n        syncTouchSize()", 1)
        print("ready hook ok")
    step = "        if (ticks % 125 == 0L && root.helperReady) root.queryTop()"
    if step in e and "syncTouchSize()" not in e.split(step)[1][:200]:
        e = e.replace(step, step + "\n        if (ticks % 250 == 0L) syncTouchSize()", 1)
        print("step hook ok")
    io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("done")
