import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
if "companion object" not in s:
    s = s.replace("class MouseAccessibilityService : AccessibilityService() {",
"""class MouseAccessibilityService : AccessibilityService() {
    companion object {
        @Volatile
        var instance: MouseAccessibilityService? = null
    }
""", 1)
if "instance = this" not in s:
    s = s.replace("    override fun onServiceConnected() {",
                  "    override fun onServiceConnected() {\n        instance = this", 1)
if "fun runMappedAction" not in s:
    s = s.replace("    /** runs a mapped action, including the pseudo actions handled here */",
"""    /** entry point for debug broadcasts / other components */
    fun runMappedAction(action: String, value: String) = fireAction(action, value)

    /** runs a mapped action, including the pseudo actions handled here */""", 1)
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service instance hook")

dp = J + r"\DebugReceiver.kt"
d = io.open(dp, encoding="utf-8").read()
if "runMappedAction" not in d:
    d = d.replace("        val action = intent.action ?: return",
"""        intent.getStringExtra("action")?.let { a ->
            MouseAccessibilityService.instance?.runMappedAction(a, intent.getStringExtra("value") ?: "")
        }
        val action = intent.action ?: return""", 1)
    io.open(dp, "w", encoding="utf-8", newline="\n").write(d)
    print("debug receiver: action hook")