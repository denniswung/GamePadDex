import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
old = """        if (Prefs.startMouseMode(prefs)) {
            // default: the pad drives our pointer; a mapped button hands it back
            handler.postDelayed({
                if (!mouseMode) {
                    toggleMouseMode(true)
                    Log.i(TAG, "auto-entered mouse mode on service start")
                }
            }, 1500L)
        }"""
assert old in s, "auto mouse block not found"
new = """        if (Prefs.startMouseMode(prefs)) {
            // default: the pad drives our pointer; a mapped button hands it back.
            // retry for up to ~12s until the root helper is actually connected,
            // otherwise the first switch happens before the engine has a display.
            var tries = 0
            val arm = object : Runnable {
                override fun run() {
                    tries++
                    if (mouseMode) return
                    val ready = root?.helperReady == true || tries > 8
                    if (ready) {
                        toggleMouseMode(true)
                        Log.i(TAG, "auto-entered mouse mode on service start (try " + tries + ")")
                    } else {
                        handler.postDelayed(this, 1500L)
                    }
                }
            }
            handler.postDelayed(arm, 1500L)
        }"""
s = s.replace(old, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("auto mouse mode retries until the helper is ready")