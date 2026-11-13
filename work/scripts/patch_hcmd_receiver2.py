import io, sys
D = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/DebugReceiver.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

d = io.open(D, encoding="utf-8").read()
bad = '''            // 直接向 root 助手发一条命令（仅调试用，例如 h 隐藏指针 / j 恢复）
            "com.dennis.dexpad.HCMD" -> {
                val cmd = intent.getStringExtra("cmd") ?: return
                val svc = EngineState
                EngineState.lastError = EngineState.lastError
                Log.i("DexPadDebug", "hcmd '$cmd'")
                com.dennis.dexpad.coreHelperBridge.send(cmd)
            }
'''
good = '''            // 直接向 root 助手发一条命令（仅调试用，例如 h 隐藏指针 / j 恢复）
            "com.dennis.dexpad.HCMD" -> {
                val cmd = intent.getStringExtra("cmd") ?: return
                Log.i("DexPadDebug", "hcmd '$cmd' -> ${EngineService.sendRaw(cmd)}")
            }
'''
if bad not in d:
    print("MISS receiver"); sys.exit(1)
d = d.replace(bad, good, 1)
io.open(D, "w", encoding="utf-8", newline="\n").write(d)
print("receiver ok")

e = io.open(E, encoding="utf-8").read()
if "fun sendRaw(" not in e:
    # 在 companion object 里放静态引用
    if "companion object" in e:
        idx = e.index("companion object")
        close = e.index("}", idx)
        ins = "\n        /** 调试用：向助手发原始命令 */\n        fun sendRaw(cmd: String): Boolean = instance?.root?.raw(cmd) ?: false\n"
        e = e[:close] + ins + e[close:]
        # 记录实例
        e = e.replace("        /** 调试用：向助手发原始命令 */",
                      "        @Volatile\n        var instance: EngineService? = null\n\n        /** 调试用：向助手发原始命令 */", 1)
    else:
        print("MISS companion"); sys.exit(1)
    # onCreate 里登记
    e = e.replace("    override fun onCreate() {", "    override fun onCreate() {\n        instance = this", 1)
    e = e.replace("    override fun onDestroy() {", "    override fun onDestroy() {\n        if (instance === this) instance = null", 1)
    io.open(E, "w", encoding="utf-8", newline="\n").write(e)
    print("engine ok")
else:
    print("already")
