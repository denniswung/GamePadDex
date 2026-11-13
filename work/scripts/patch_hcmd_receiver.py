import io
D = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/DebugReceiver.kt"
s = io.open(D, encoding="utf-8").read()
old = '''            "com.dennis.dexpad.MODE" -> {'''
new = '''            // 直接向 root 助手发一条命令（仅调试用，例如 h 隐藏指针 / j 恢复）
            "com.dennis.dexpad.HCMD" -> {
                val cmd = intent.getStringExtra("cmd") ?: return
                val svc = EngineState
                EngineState.lastError = EngineState.lastError
                Log.i("DexPadDebug", "hcmd '$cmd'")
                com.dennis.dexpad.coreHelperBridge.send(cmd)
            }
            "com.dennis.dexpad.MODE" -> {'''
s = s.replace(old, new, 1)
io.open(D, "w", encoding="utf-8", newline="\n").write(s)
print("ok")
