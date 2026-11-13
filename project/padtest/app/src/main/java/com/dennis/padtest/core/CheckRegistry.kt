package com.dennis.padtest.core

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * 自检/用例结果登记处。
 *
 * 每个测试点有一个稳定的 id（例如 "LINK.DEVICES"），三个状态：
 * PASS / FAIL / UNKNOWN（未检测）。失败必须带原因，便于直接定位。
 */
object CheckRegistry {

    enum class Status { PASS, FAIL, UNKNOWN }

    data class Check(
        val id: String,
        val page: String,
        val title: String,
        var status: Status = Status.UNKNOWN,
        var reason: String = "",
        var updatedAt: Long = 0L,
    )

    private val checks = LinkedHashMap<String, Check>()

    fun define(id: String, page: String, title: String) {
        checks.getOrPut(id) { Check(id, page, title) }
    }

    fun pass(id: String, note: String = "") = set(id, Status.PASS, note)
    fun fail(id: String, reason: String) = set(id, Status.FAIL, reason)
    fun unknown(id: String, reason: String = "") = set(id, Status.UNKNOWN, reason)

    private fun set(id: String, status: Status, note: String) {
        val c = checks[id] ?: return
        c.status = status
        c.reason = note
        c.updatedAt = System.currentTimeMillis()
    }

    fun all(): List<Check> = checks.values.toList()

    fun counts(): Triple<Int, Int, Int> {
        var p = 0; var f = 0; var u = 0
        for (c in checks.values) when (c.status) {
            Status.PASS -> p++
            Status.FAIL -> f++
            Status.UNKNOWN -> u++
        }
        return Triple(p, f, u)
    }

    fun reset() {
        for (c in checks.values) {
            c.status = Status.UNKNOWN
            c.reason = ""
            c.updatedAt = 0L
        }
    }

    // ------------------------------------------------------------ 会话

    private const val SP = "session"

    fun startSession(ctx: Context) {
        prefs(ctx).edit().putLong("started_at", System.currentTimeMillis()).apply()
    }

    fun stopSession(ctx: Context) {
        prefs(ctx).edit().putLong("stopped_at", System.currentTimeMillis()).apply()
    }

    fun sessionStart(ctx: Context): Long = prefs(ctx).getLong("started_at", 0L)

    fun sessionStop(ctx: Context): Long = prefs(ctx).getLong("stopped_at", 0L)

    private fun prefs(ctx: Context): SharedPreferences =
        ctx.applicationContext.getSharedPreferences(SP, Context.MODE_PRIVATE)

    // ------------------------------------------------------------ 报告

    fun reportJson(ctx: Context): String {
        val (p, f, u) = counts()
        val root = JSONObject()
        root.put("generated_at", ProbeEvent.timeText(System.currentTimeMillis()))
        root.put("session_start", sessionStart(ctx))
        root.put("session_stop", sessionStop(ctx))
        root.put("pass", p)
        root.put("fail", f)
        root.put("unknown", u)
        val arr = org.json.JSONArray()
        for (c in checks.values) {
            val o = JSONObject()
            o.put("id", c.id)
            o.put("page", c.page)
            o.put("title", c.title)
            o.put("status", c.status.name)
            o.put("reason", c.reason)
            val recent = ProbeBus.recent(5).map { it.oneLine() }
            o.put("recent_logs", org.json.JSONArray(recent))
            arr.put(o)
        }
        root.put("checks", arr)
        return root.toString(2)
    }

    fun reportText(ctx: Context): String {
        val sb = StringBuilder()
        val (p, f, u) = counts()
        sb.append("手柄映射测试报告\n")
        sb.append("生成时间: ").append(ProbeEvent.timeText(System.currentTimeMillis())).append('\n')
        val s = sessionStart(ctx)
        if (s > 0) {
            sb.append("会话开始: ").append(ProbeEvent.timeText(s)).append('\n')
            sb.append("会话结束: ").append(
                if (sessionStop(ctx) > 0) ProbeEvent.timeText(sessionStop(ctx)) else "进行中",
            ).append('\n')
        }
        sb.append("通过 ").append(p).append(" · 失败 ").append(f).append(" · 未测 ").append(u).append('\n')
        sb.append("----------------------------------------\n")
        for (c in checks.values) {
            sb.append(if (c.status == Status.PASS) "[PASS] " else if (c.status == Status.FAIL) "[FAIL] " else "[ -- ] ")
            sb.append(c.page).append(" / ").append(c.title)
            if (c.reason.isNotEmpty()) sb.append("  —— ").append(c.reason)
            sb.append('\n')
            if (c.status == Status.FAIL) {
                for (l in ProbeBus.recent(5)) sb.append("      · ").append(l.oneLine()).append('\n')
            }
        }
        return sb.toString()
    }
}
