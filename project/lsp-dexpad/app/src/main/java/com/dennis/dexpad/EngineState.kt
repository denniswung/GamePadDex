package com.dennis.dexpad

/** Shared, volatile view of the engine for the configuration activity. */
object EngineState {
    @Volatile var serviceRunning = false
    @Volatile var connected = false

    /** 前台包名（助手 T 命令回填，用于判断是否桌面） */
    @Volatile var topPackage = ""
    @Volatile var modeOn = false
    @Volatile var devices: List<String> = emptyList()
    @Volatile var lastError: String = ""

    /** helper capability report from `?` (name -> 1/0) */
    @Volatile var caps: Map<String, Int> = emptyMap()

    /** CLOCK_MONOTONIC ms when the helper read the newest key event */
    @Volatile var lastEventMs: Long = 0L

    // ---- input latency (helper read -> action dispatched) ----
    @Volatile var latCount: Int = 0
    @Volatile var latMax: Long = 0L
    @Volatile var latSum: Long = 0L

    fun latReset() {
        latCount = 0
        latMax = 0L
        latSum = 0L
    }

    fun latAdd(ms: Long) {
        if (ms < 0 || ms > 5000) return
        latCount++
        latSum += ms
        if (ms > latMax) latMax = ms
    }
}
