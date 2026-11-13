import io, re
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\MouseAccessibilityService.kt"
s = io.open(p, encoding="utf-8").read()
if "companion object" not in s:
    # put the companion object right before the first member after the class opening brace
    m = re.search(r"\nclass MouseAccessibilityService[^\n]*\{\n", s)
    assert m, "class decl not found"
    idx = m.end()
    s = s[:idx] + """
    companion object {
        @Volatile
        var instance: MouseAccessibilityService? = null
    }

""" + s[idx:]
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("companion inserted after class decl")