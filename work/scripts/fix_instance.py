import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"
sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
# drop the misplaced companion object
i = s.find("    companion object {\n        @Volatile\n        var instance: MouseAccessibilityService? = null\n    }")
if i >= 0:
    j = s.find("}", i) + 1
    # remove through the closing brace of the object
    k = s.find("\n    }", i)
    s = s[:i] + s[k+len("\n    }"):]
    print("companion removed")
s = s.replace("        instance = this", "        gpmService = this", 1)
if "internal var gpmService" not in s:
    s = s.rstrip() + "\n\n/** the live service instance, used by debug broadcasts */\ninternal var gpmService: MouseAccessibilityService? = null\n"
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)

dp = J + r"\DebugReceiver.kt"
d = io.open(dp, encoding="utf-8").read()
d = d.replace("MouseAccessibilityService.instance?.runMappedAction", "gpmService?.runMappedAction")
io.open(dp, "w", encoding="utf-8", newline="\n").write(d)
print("debug receiver fixed")