import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
if "mapped key" not in s:
    s = s.replace("""    private fun handleMappedButton(keyCode: Int, action: Int): Boolean {
        if (action == KeyEvent.ACTION_UP) {""",
"""    private fun handleMappedButton(keyCode: Int, action: Int): Boolean {
        if (action == KeyEvent.ACTION_DOWN) {
            Log.i(TAG, "mapped key " + keyCode + " name=" + (Prefs.keycodeButton(keyCode) ?: "?") +
                " type=" + (prefs.getString(Prefs.btnType(Prefs.keycodeButton(keyCode) ?: ""), "default")))
        }
        if (action == KeyEvent.ACTION_UP) {""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("logged")