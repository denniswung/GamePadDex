import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
svc = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse",
                   "MouseAccessibilityService.kt")
s = io.open(svc, encoding="utf-8").read()

# 1) poll interval 1500ms -> 300ms, plus a low-rate heartbeat log
s = s.replace("            handler.postDelayed(this, 1500L)", "            handler.postDelayed(this, 300L)")
if "poll#" not in s:
    s = s.replace("""    private val displayWatch = object : Runnable {
        override fun run() {
            try {
                pickDisplay()""",
                  """    private var pollCount = 0

    private val displayWatch = object : Runnable {
        override fun run() {
            try {
                pollCount++
                pickDisplay()
                if (pollCount % 10 == 0) {
                    Log.i(TAG, "poll#" + pollCount + " focus=" + focusedDisplayId() +
                        " target=" + (display?.displayId ?: -1))
                }""", 1)

# 2) DisplayManager callbacks: re-attach immediately (debounced 100ms)
s = s.replace("            handler.postDelayed(displayRefresh, 600L)", "            handler.postDelayed(displayRefresh, 100L)")

# 3) window events also drive the refresh (DeX desktop appearing, app switching)
if "TYPE_WINDOWS_CHANGED" not in s:
    s = s.replace("""    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    }""",
                  """    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // DeX window model reports focus changes here, not via isFocused
        when (event?.eventType) {
            AccessibilityEvent.TYPE_WINDOWS_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handler.removeCallbacks(displayRefresh)
                handler.postDelayed(displayRefresh, 120L)
            }
        }
    }""", 1)

io.open(svc, "w", encoding="utf-8", newline="\n").write(s)
print("patched: 300ms poll + immediate refresh hook")
