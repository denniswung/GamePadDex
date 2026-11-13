import io, sys
A = "/mnt/e/Dennis.GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"
A = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/ActionRouter.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

a = io.open(A, encoding="utf-8").read()
old = """        /** ignore stick input while the pointer is being centred */
        fun lockCenterFor(ms: Long)"""
new = """        /** ignore stick input while the pointer is being centred */
        fun lockCenterFor(ms: Long)

        /** the pointer must be visible again (e.g. it was hidden while idle) */
        fun onPointerNeeded()"""
if old not in a:
    print("MISS iface"); sys.exit(1)
a = a.replace(old, new, 1)

old2 = """            Action.CENTER_CURSOR -> {
                val (w, h) = host.displayState().size(display)"""
new2 = """            Action.CENTER_CURSOR -> {
                // 指针可能被「空闲隐藏」销毁了：先恢复，否则居中看不到结果
                host.onPointerNeeded()
                val (w, h) = host.displayState().size(display)"""
if old2 not in a:
    print("MISS center"); sys.exit(1)
a = a.replace(old2, new2, 1)
io.open(A, "w", encoding="utf-8", newline="\n").write(a)
print("router ok")

e = io.open(E, encoding="utf-8").read()
anchor = "            override fun lockCenterFor(ms: Long) {"
if anchor not in e:
    print("MISS engine anchor"); sys.exit(1)
e = e.replace(anchor, """            override fun onPointerNeeded() {
                lastUserInputAt = SystemClock.elapsedRealtime()
                showPointer()
            }

""" + anchor, 1)
io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("engine ok")
