import io, os
root = r"E:\Dennis\GamePadDex复刻\project"
svc = os.path.join(root, "app", "src", "main", "java", "com", "dennis", "gamepadmouse",
                   "MouseAccessibilityService.kt")
s = io.open(svc, encoding="utf-8").read()

# 1) make the ATTACH log free of anything that can throw on a DeX display
old_log = [l for l in s.splitlines() if "ATTACH display" in l]
for l in old_log:
    s = s.replace(l, '        android.util.Log.i(TAG, "ATTACH display " + target.displayId)')

# 2) harden pickDisplay: never leave the engine without a display
if "private fun pickDisplay() {\n        try {" not in s:
    s = s.replace("    private fun pickDisplay() {",
                  """    private fun pickDisplay() {
        try {
            pickDisplayImpl()
        } catch (t: Throwable) {
            Log.e(TAG, "pickDisplay failed: " + t, t)
            // never lose the pointer: fall back to the default display
            val fallback = displayManager.getDisplay(Display.DEFAULT_DISPLAY) ?: return
            if (display?.displayId != fallback.displayId) {
                display = fallback
                try {
                    engine?.attachDisplay(fallback)
                } catch (t2: Throwable) {
                    Log.e(TAG, "attach fallback failed: " + t2, t2)
                }
            }
        }
    }

    private fun pickDisplayImpl() {""", 1)

io.open(svc, "w", encoding="utf-8", newline="\n").write(s)
print("pickDisplay hardened")
