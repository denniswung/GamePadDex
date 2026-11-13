import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
if "toast(\"映射\"" not in s:
    s = s.replace('''    private fun fireAction(action: String, value: String) {
        Log.i(TAG, "fireAction " + action + " " + value)''',
'''    private fun fireAction(action: String, value: String) {
        Log.i(TAG, "fireAction " + action + " " + value)
        try {
            // visible feedback: lets the user see that a remap fired at all
            android.widget.Toast.makeText(this, "映射: " + action + (if (value.isBlank()) "" else " " + value),
                android.widget.Toast.LENGTH_SHORT).show()
        } catch (t: Throwable) {
        }''', 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("toast added")