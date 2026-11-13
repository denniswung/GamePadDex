import io
p = r"E:\Dennis\GamePadDex复刻\project\app\src\main\java\com\dennis\gamepadmouse\PointerEngine.kt"
s = io.open(p, encoding="utf-8").read()
anchor = """        if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {"""
assert anchor in s, "gate not found"
new = """        if (sx != 0f || sy != 0f) {
            android.util.Log.i("GpmPointer", "gate sx=$sx sy=$sy mag=$scrollMag dt=${now - lastScrollAt} rootOk=${root?.isRunning} native=$nativePointer")
        }
        if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {"""
s = s.replace(anchor, new, 1)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
print("gate log added")