import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

# media keys: prefer display-targeted KeyEvent injection, then uinput, then AudioManager
sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
old = """        try {
            val r = root
            if (r != null && r.isRunning) {
                val linux = KeyMap.toLinux(androidCode)
                if (linux != null) {
                    r.key(linux, true)
                    r.key(linux, false)
                    return
                }
            }"""
new = """        try {
            val r = root
            if (r != null && r.isRunning) {
                // display targeted first: media keys must stay on the DeX screen
                val disp = targetDisplayId()
                if (r.helperReady && r.pointKey(disp, androidCode)) {
                    Log.i(TAG, "media key " + androidCode + " -> display " + disp)
                    return
                }
                val linux = KeyMap.toLinux(androidCode)
                if (linux != null) {
                    r.key(linux, true)
                    r.key(linux, false)
                    return
                }
            }"""
assert old in s, "mediaKey block not found"
s = s.replace(old, new, 1)
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("mediaKey: display targeted first")

# ActionDispatcher media actions: route through the service when possible
ap = J + r"\ActionDispatcher.kt"
a = io.open(ap, encoding="utf-8").read()
print("action dispatcher untouched (service handles mapped actions first)")