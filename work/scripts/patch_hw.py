import io
root = r"E:\Dennis\GamePadDex复刻\project"
J = root + r"\app\src\main\java\com\dennis\gamepadmouse"

rp = J + r"\RootInput.kt"
r = io.open(rp, encoding="utf-8").read()
r = r.replace("""    fun fullscreenClick(displayId: Int, screenWidth: Int = 0): Boolean {
        if (!isRunning) return false
        send("J $displayId $screenWidth")""",
"""    fun fullscreenClick(displayId: Int, screenWidth: Int = 0, screenHeight: Int = 0): Boolean {
        if (!isRunning) return false
        send("J $displayId $screenWidth $screenHeight")""", 1)
io.open(rp, "w", encoding="utf-8", newline="\n").write(r)
print("rootinput w+h")

sp = J + r"\MouseAccessibilityService.kt"
s = io.open(sp, encoding="utf-8").read()
s = s.replace("root?.fullscreenClick(dispNow, screenWidth ?: 0)", "root?.fullscreenClick(dispNow, screenWidth ?: 0, screenHeight ?: 0)")
if "val screenHeight: Int?" not in s:
    s = s.replace("""    val screenWidth: Int?
        get() = engine?.width""",
"""    val screenWidth: Int?
        get() = engine?.width
    val screenHeight: Int?
        get() = engine?.height2""", 1)
io.open(sp, "w", encoding="utf-8", newline="\n").write(s)
print("service passes h")

ep = J + r"\PointerEngine.kt"
e = io.open(ep, encoding="utf-8").read()
if "val height2: Int get() = displayHeight" not in e:
    e = e.replace("    val width: Int get() = displayWidth",
                  "    val width: Int get() = displayWidth\n    val height2: Int get() = displayHeight", 1)
    io.open(ep, "w", encoding="utf-8", newline="\n").write(e)
    print("engine height accessor")