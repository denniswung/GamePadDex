package com.dennis.padtest.core

import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.CopyOnWriteArrayList

/**
 * 进程内事件总线。
 *
 * 三个作用：
 * 1. 收集所有被捕获的事件（环形缓冲，默认 3000 条），供日志面板与报告使用；
 * 2. 同步镜像到 logcat（tag = PadProbe），让 adb 自动化可以直接断言；
 * 3. 给 UI 提供**节流后**的回调，避免高频鼠标移动导致主线程掉帧。
 */
object ProbeBus {

    const val TAG = "PadProbe"
    private const val CAPACITY = 3000
    private const val UI_MIN_INTERVAL_MS = 60L

    private val buffer = ArrayDeque<ProbeEvent>(CAPACITY)
    private val listeners = CopyOnWriteArrayList<(ProbeEvent) -> Unit>()
    private val handler = Handler(Looper.getMainLooper())
    private var uiPending = false
    private var lastUiFlush = 0L

    /** 最近一次收到某类事件的时刻（自检页用） */
    private val lastAt = HashMap<Src, Long>()
    private var lastAnyAt = 0L

    fun post(event: ProbeEvent) {
        synchronized(buffer) {
            buffer.addLast(event)
            while (buffer.size > CAPACITY) buffer.removeFirst()
            lastAt[event.src] = event.at
            lastAnyAt = event.at
        }
        // 镜像到 logcat：adb 侧可直接 grep
        Log.i(TAG, "${event.src.name}/${event.kind} ${event.detail}")

        if (!uiPending) {
            val now = android.os.SystemClock.elapsedRealtime()
            val delay = (UI_MIN_INTERVAL_MS - (now - lastUiFlush)).coerceAtLeast(0)
            uiPending = true
            handler.postDelayed({
                uiPending = false
                lastUiFlush = android.os.SystemClock.elapsedRealtime()
                val copy = listeners.toList()
                for (l in copy) runCatching { l(event) }
            }, delay)
        }
    }

    fun sample(src: Src, kind: String, detail: String, extra: Map<String, String> = emptyMap()) {
        post(ProbeEvent(src = src, kind = kind, detail = detail, extra = extra))
    }

    fun addListener(l: (ProbeEvent) -> Unit) {
        listeners.add(l)
    }

    fun removeListener(l: (ProbeEvent) -> Unit) {
        listeners.remove(l)
    }

    fun snapshot(): List<ProbeEvent> = synchronized(buffer) { buffer.toList() }

    fun recent(n: Int): List<ProbeEvent> = synchronized(buffer) {
        val from = (buffer.size - n).coerceAtLeast(0)
        buffer.toList().subList(from, buffer.size)
    }

    fun clear() {
        synchronized(buffer) {
            buffer.clear()
            lastAt.clear()
            lastAnyAt = 0L
        }
        Log.i(TAG, "buffer cleared")
    }

    /** 某来源最近一次事件的时刻（elapsedRealtime），没收到过返回 0 */
    fun lastEventAt(src: Src): Long = synchronized(buffer) { lastAt[src] ?: 0L }

    fun lastAnyEventAt(): Long = synchronized(buffer) { lastAnyAt }

    fun count(): Int = synchronized(buffer) { buffer.size }
}
