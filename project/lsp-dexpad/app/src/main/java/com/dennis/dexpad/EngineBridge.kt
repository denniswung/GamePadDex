package com.dennis.dexpad

/** 极小的进程内桥：让广播接收器等外部入口能向 root 助手发一条原始命令。 */
object EngineBridge {
    @Volatile
    var service: EngineService? = null

    fun sendRaw(cmd: String): Boolean = service?.sendCmd(cmd) ?: false
}
