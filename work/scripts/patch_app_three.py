import io, sys
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"

r = io.open(R, encoding="utf-8").read()
old = '''    fun centerCursor(maxX: Int, maxY: Int, park: Boolean = false, rotation: Int = 0) {
        send("O $maxX $maxY ${if (park) 1 else 0} $rotation")
    }'''
new = '''    fun centerCursor(maxX: Int, maxY: Int, park: Boolean = false, rotation: Int = 0, gain: Float = 2.16f) {
        send(String.format(java.util.Locale.US, "O %d %d %d %d %.2f",
            maxX, maxY, if (park) 1 else 0, rotation, gain))
    }'''
if old not in r:
    print("MISS rootinput")
else:
    r = r.replace(old, new, 1)
    io.open(R, "w", encoding="utf-8", newline="\n").write(r)
    print("rootinput ok")

a = io.open(A, encoding="utf-8").read()
old2 = '''                host.onPointerNeeded()
                host.centerPointer()'''
new2 = '''                host.onPointerNeeded()'''
if old2 in a:
    a = a.replace(old2, new2, 1)
    print("router: removed centerPointer")

old3 = '''                host.lockCenterFor(300)
                // 位移已由 centerPointer() 一步完成，这里不再用助手的"夹角"算法'''
new3 = '''                host.lockCenterFor(700)
                // 助手侧：有界小步夹角 + 按增益一步到中心（见 gpminput.c cmd_center）'''
if old3 in a:
    a = a.replace(old3, new3, 1)
    print("router: lock 700")

old4 = '''                val rot = host.displayState().rotation(display)'''
new4 = '''                val rot = host.displayState().rotation(display)
                val gain = host.prefs().centerGain'''
if old4 in a:
    a = a.replace(old4, new4, 1)
    print("router: gain")

old5 = 'root.centerCursor(w, h, host.isPhone(), rot)'
new5 = 'root.centerCursor(w, h, host.isPhone(), rot, gain)'
if old5 in a:
    a = a.replace(old5, new5, 1)
    print("router: center call")
io.open(A, "w", encoding="utf-8", newline="\n").write(a)
