import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

rp = J + r"\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
r = r.replace("""    fun fullscreenClick(displayId: Int, screenWidth: Int = 0): Boolean {
        if (!isRunning) return false
        send("J $displayId $screenWidth")
        return helperReady
    }""",
"""    fun fullscreenClick(displayId: Int, screenWidth: Int = 0): Boolean {
        if (!isRunning) return false
        send("J $displayId $screenWidth")
        return true            // fire and forget: helperReady lags right after a restart
    }""", 1)
io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
print("fullscreenClick no longer gated on helperReady")

sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
if "postDelayed({ root?.fullscreenClick" not in s:
    s = s.replace("""                val rootOk = try { root?.fullscreenClick(dispNow, screenWidth ?: 0) ?: false } catch (t: Throwable) { false }""",
"""                val rootOk = try { root?.fullscreenClick(dispNow, screenWidth ?: 0) ?: false } catch (t: Throwable) { false }
                // a restarting helper can drop the first click: retry once shortly after
                handler.postDelayed({
                    runCatching { root?.fullscreenClick(dispNow, screenWidth ?: 0) }
                }, 1200L)""", 1)
    io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
    print("retry added")