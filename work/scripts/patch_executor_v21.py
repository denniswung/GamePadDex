import io

p = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/v2/Executor.kt"
s = io.open(p, encoding="utf-8").read()

s = s.replace("import android.os.Vibrator", "import android.os.Vibrator\nimport android.widget.Toast")
s = s.replace("""            "scroll_swipe_up" -> r.swipeV(d, -(h * 0.45f).toInt(), 300, w, h, -1)
            "scroll_swipe_down" -> r.swipeV(d, (h * 0.45f).toInt(), 300, w, h, -1)
            "scroll_swipe_left" -> r.swipeH(d, -(w * 0.45f).toInt(), 300, w, h, -1)
            "scroll_swipe_right" -> r.swipeH(d, (w * 0.45f).toInt(), 300, w, h, -1)""",
"""            "scroll_swipe_up" -> r.swipeV(d, -(h * cfg.stepPercent / 100f).toInt(), 300, w, h, -1)
            "scroll_swipe_down" -> r.swipeV(d, (h * cfg.stepPercent / 100f).toInt(), 300, w, h, -1)
            "scroll_swipe_left" -> r.swipeH(d, -(w * cfg.slideWidthPercent / 100f).toInt(), 300, w, h, -1)
            "scroll_swipe_right" -> r.swipeH(d, (w * cfg.slideWidthPercent / 100f).toInt(), 300, w, h, -1)""")

s = s.replace("""            "close_app" -> r.closeApp()""",
"""            "close_app" -> r.closeApp()
            "force_stop" -> { r.closeApp(); toast("已强制停止前台应用"); haptic(60) }
            "help" -> showHelp()
            "toggle_screen" -> r.powerKey()""")

s = s.replace("""    fun startHold(button: String, action: String, value: String) {
        stopHold(button)
        val startedAt = SystemClock.elapsedRealtime()""",
"""    fun startHold(button: String, action: String, value: String, viaCombo: Boolean) {
        stopHold(button)
        val delay = when (action) {
            "scroll_swipe_left", "scroll_swipe_right" -> if (viaCombo) cfg.xlbHoldDelayMs else cfg.lbHoldDelayMs
            "scroll_swipe_up", "scroll_swipe_down", "wheel_up", "wheel_down",
            "wheel_left", "wheel_right" -> cfg.lbHoldDelayMs
            "volume_up", "volume_down", "mute" -> cfg.volumeHoldDelayMs
            "zoom_in", "zoom_out" -> 100L
            else -> cfg.startDelayMs
        }
        val startedAt = SystemClock.elapsedRealtime()""")

s = s.replace("""        handler.postDelayed(r, cfg.startDelayMs)
        holds[button] = r""", """        handler.postDelayed(r, delay)
        holds[button] = r""")

s = s.replace("""                val held = SystemClock.elapsedRealtime() - startedAt
                val delay = if (held > 1000L) cfg.accelMs else cfg.repeatMs
                handler.postDelayed(this, delay)""",
"""                val held = SystemClock.elapsedRealtime() - startedAt
                val interval = if (held > 1000L) cfg.accelMs else cfg.repeatMs
                handler.postDelayed(this, interval)""")

s = s.replace("""    fun stopAll() {""",
"""    private fun toast(text: String) {
        try {
            Toast.makeText(context, text, Toast.LENGTH_SHORT).show()
        } catch (_: Throwable) {
        }
    }

    private fun showHelp() {
        try {
            val i = android.content.Intent(context, HelpActivity::class.java)
            i.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(i)
        } catch (t: Throwable) {
            Log.w("PadCtlV2", "help: ${t.message}")
        }
    }

    fun stopAll() {""")

io.open(p, "w", encoding="utf-8", newline="\n").write(s)

# KeyMachine host signature is separate; adjust EngineV2 host implementation later.
print("executor patched")
