import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
if "window dump:" not in s:
    s = s.replace("""        val ws = try { windows } catch (t: Throwable) { null } ?: return result""",
"""        val ws = try { windows } catch (t: Throwable) { null } ?: return result
        for (w in ws) {
            Log.i(TAG, "window dump: id=" + w.id + " type=" + w.type + " display=" + w.displayId +
                " active=" + w.isActive + " focused=" + w.isFocused + " title=" + w.title)
        }""", 1)
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("window dump added")