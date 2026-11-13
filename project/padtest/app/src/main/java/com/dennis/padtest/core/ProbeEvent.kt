package com.dennis.padtest.core

import android.os.SystemClock

/**
 * 事件来源。区分来源是为了判断“链路断点”：
 * 收到 MOUSE/WHEEL 说明映射程序的 uinput 注入被系统分发到了本 App；
 * 收到 TOUCH 说明走的是触摸手势后端；收到 KEY 说明走的是按键注入。
 */
enum class Src(val label: String) {
    MOUSE("鼠标"),
    WHEEL("滚轮"),
    TOUCH("触摸"),
    KEY("按键"),
    SYSTEM("系统"),
}

/**
 * 一条被捕获的事件。
 *
 * @param at 事件到达本 App 的时刻（elapsedRealtime，单调递增，用于算间隔；展示时换算成墙钟）
 * @param kind 动作类型，例如 move / click / scroll / key / swipe
 * @param detail 关键参数，例如 "x=120 y=340" 或 "KEYCODE_BACK"
 * @param wallClock 墙钟时间（展示用）
 */
data class ProbeEvent(
    val at: Long = SystemClock.elapsedRealtime(),
    val wallClock: Long = System.currentTimeMillis(),
    val src: Src,
    val kind: String,
    val detail: String,
    val extra: Map<String, String> = emptyMap(),
) {
    fun oneLine(): String = "%s %s %s %s".format(timeText(wallClock), src.label, kind, detail)

    fun csv(): String =
        "%s,%s,%s,%s".format(timeText(wallClock), src.name, kind, detail.replace(',', ';'))

    companion object {
        fun timeText(wall: Long): String {
            val fmt = java.text.SimpleDateFormat("HH:mm:ss.SSS", java.util.Locale.US)
            return fmt.format(java.util.Date(wall))
        }
    }
}
