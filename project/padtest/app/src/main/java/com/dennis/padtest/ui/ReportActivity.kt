package com.dennis.padtest.ui

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.Exporter
import com.dennis.padtest.core.ProbeBus

/**
 * 七、结果汇总。
 *
 * 开始/结束测试（记录时间窗）→ 汇总 PASS/FAIL/UNKNOWN 数量 → 失败项各列出最近 5 条日志 → 可导出。
 */
class ReportActivity : ProbeActivity() {

    private lateinit var summaryView: TextView
    private lateinit var detailView: TextView
    private lateinit var exportView: TextView
    private val handler = Handler(Looper.getMainLooper())

    private var lastFingerprint = ""

    private val tick = object : Runnable {
        override fun run() {
            val (p, f, u) = CheckRegistry.counts()
            val fp = "$p-$f-$u-" + CheckRegistry.sessionStart(this@ReportActivity) +
                "-" + CheckRegistry.sessionStop(this@ReportActivity) + "-" + ProbeBus.count()
            if (fp != lastFingerprint) {
                lastFingerprint = fp
                render()
            }
            handler.postDelayed(this, 500)
        }
    }

    override fun buildContent(): View {
        val col = page("测试报告", "开始测试 → 逐页验证 → 结束测试 → 导出")

        summaryView = mono("", 12f, 0xFF4FC3F7.toInt())
        detailView = mono("", 11f)
        exportView = mono("", 11f, 0xFF9FB0BE.toInt())

        val bar = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        bar.addView(button("开始测试") {
            CheckRegistry.startSession(this)
            ProbeBus.sample(com.dennis.padtest.core.Src.SYSTEM, "session", "start")
            render()
        })
        bar.addView(button("结束测试") {
            CheckRegistry.stopSession(this)
            ProbeBus.sample(com.dennis.padtest.core.Src.SYSTEM, "session", "stop")
            render()
        })
        col.addView(bar)

        val bar2 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        bar2.addView(button("导出报告 TXT") {
            val f = Exporter.exportReportText(this)
            exportView.text = "已导出：${f.absolutePath}"
        })
        bar2.addView(button("导出报告 JSON") {
            val f = Exporter.exportReportJson(this)
            exportView.text = "已导出：${f.absolutePath}"
        })
        bar2.addView(button("清零结果") {
            CheckRegistry.reset()
            render()
        })
        col.addView(bar2)

        col.addView(card(summaryView))
        col.addView(card(exportView))
        col.addView(card(detailView))
        return scroll(col)
    }

    private fun render() {
        val (p, f, u) = CheckRegistry.counts()
        val start = CheckRegistry.sessionStart(this)
        val stop = CheckRegistry.sessionStop(this)
        summaryView.text = buildString {
            append("通过 ").append(p).append(" · 失败 ").append(f).append(" · 未测 ").append(u).append('\n')
            if (start > 0) {
                append("会话开始 ").append(com.dennis.padtest.core.ProbeEvent.timeText(start)).append('\n')
                append("会话结束 ").append(
                    if (stop > 0) com.dennis.padtest.core.ProbeEvent.timeText(stop) else "进行中",
                )
            } else {
                append("未开始会话（点「开始测试」记录时间窗）")
            }
        }

        val sb = StringBuilder()
        var lastPage = ""
        for (c in CheckRegistry.all()) {
            if (c.page != lastPage) {
                sb.append("\n【").append(c.page).append("】\n")
                lastPage = c.page
            }
            sb.append(
                when (c.status) {
                    CheckRegistry.Status.PASS -> "  [PASS] "
                    CheckRegistry.Status.FAIL -> "  [FAIL] "
                    CheckRegistry.Status.UNKNOWN -> "  [ -- ] "
                },
            ).append(c.title)
            if (c.reason.isNotEmpty()) sb.append("  —— ").append(c.reason)
            sb.append('\n')
            if (c.status == CheckRegistry.Status.FAIL) {
                for (l in ProbeBus.recent(5)) sb.append("        · ").append(l.oneLine()).append('\n')
            }
        }
        detailView.text = sb.toString()
        refreshOverlay()
    }

    override fun onResume() {
        super.onResume()
        handler.post(tick)
    }

    override fun onPause() {
        handler.removeCallbacks(tick)
        super.onPause()
    }
}
