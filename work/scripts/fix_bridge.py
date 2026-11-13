import io
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
s = io.open(E, encoding="utf-8").read()

broken = '''            
        @Volatile
        var instance: EngineService? = null

        /** 调试用：向助手发原始命令 */
        fun sendRaw(cmd: String): Boolean = instance?.root?.raw(cmd) ?: false
} catch (t: Throwable) {'''
if broken not in s:
    # 容忍空白差异：按关键行清理
    import re
    s = s.replace("@Volatile\n        var instance: EngineService? = null\n", "")
    s = s.replace("        /** 调试用：向助手发原始命令 */\n        fun sendRaw(cmd: String): Boolean = instance?.root?.raw(cmd) ?: false\n", "")
else:
    s = s.replace(broken, '''            } catch (t: Throwable) {''', 1)

s = s.replace("    override fun onCreate() {\n        instance = this\n", "    override fun onCreate() {\n        EngineBridge.service = this\n", 1)
s = s.replace("        if (instance === this) instance = null\n", "        if (EngineBridge.service === this) EngineBridge.service = null\n", 1)

# 加上 sendCmd 方法（root 就在这个类里）
if "fun sendCmd(" not in s:
    s = s.replace("    override fun onDestroy() {",
"""    /** 调试/测试用：把一条原始命令转发给 root 助手 */
    fun sendCmd(cmd: String): Boolean = runCatching { root.raw(cmd); true }.getOrDefault(false)

    override fun onDestroy() {""", 1)

io.open(E, "w", encoding="utf-8", newline="\n").write(s)
print("engine fixed")

bridge = '''package com.dennis.dexpad

/** 极小的进程内桥：让广播接收器等外部入口能向 root 助手发一条原始命令。 */
object EngineBridge {
    @Volatile
    var service: EngineService? = null

    fun sendRaw(cmd: String): Boolean = service?.sendCmd(cmd) ?: false
}
'''
io.open("/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineBridge.kt",
        "w", encoding="utf-8", newline="\n").write(bridge)
print("bridge written")

D = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/DebugReceiver.kt"
d = io.open(D, encoding="utf-8").read().replace("EngineService.sendRaw(cmd)", "EngineBridge.sendRaw(cmd)")
io.open(D, "w", encoding="utf-8", newline="\n").write(d)
print("receiver fixed")
