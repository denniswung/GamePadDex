import io, sys
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()
if 'root.raw("j")' in s:
    print("already")
    sys.exit(0)
anchor = "        root.selftest()\n        EngineState.connected = true"
if anchor not in s:
    print("MISS"); sys.exit(1)
s = s.replace(anchor, """        root.selftest()
        // 助手重启后鼠标设备可能仍处于「被空闲隐藏」状态：强制重建一次，
        // 否则光标设备不存在，移动/点击都会静默失效（点了没反应）。
        pointerHidden = false
        root.raw("j")
        syncTouchSize()
        EngineState.connected = true""", 1)
io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
