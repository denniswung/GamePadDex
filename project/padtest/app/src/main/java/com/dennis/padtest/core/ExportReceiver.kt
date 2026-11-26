package com.dennis.padtest.core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * v1.2：自动化导出钩子（仅测试台 App，无敏感权限）。
 *
 *   adb shell am broadcast -a com.dennis.padtest.EXPORT \
 *       -n com.dennis.padtest/.core.ExportReceiver --es what report|log --es fmt json|csv
 *
 * 写出路径与文件大小会打印到 logcat（tag=PadProbe），套件可直接读取 JSON。
 */
class ExportReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val what = intent.getStringExtra("what") ?: "report"
        val fmt = intent.getStringExtra("fmt") ?: "json"
        val f = when {
            what == "log" && fmt == "csv" -> Exporter.exportLogCsv(context)
            what == "log" -> Exporter.exportLogJson(context)
            fmt == "text" -> Exporter.exportReportText(context)
            else -> Exporter.exportReportJson(context)
        }
        Log.i(ProbeBus.TAG, "EXPORT what=$what fmt=$fmt path=${f.absolutePath} size=${f.length()}")
        // 同时把埋点摘要打一行，便于 adb 直接断言（不替代 JSON）
        Log.i(
            ProbeBus.TAG,
            "METRICS touch.frames=${PadMetrics.touchFrames} maxGap=${PadMetrics.touchMaxGapMs}ms " +
                "left=${PadMetrics.leftOffset} right=${PadMetrics.rightOffset} " +
                "fixedArea=${PadMetrics.fixedAreaScrolls}",
        )
    }
}
