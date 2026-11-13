package com.dennis.padtest.core

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import java.io.File

/**
 * 导出：写到 App 专属外部目录（无需任何权限），并可通过系统分享发出。
 * 路径示例：/sdcard/Android/data/com.dennis.padtest/files/export/xxx.csv
 */
object Exporter {

    private fun dir(ctx: Context): File {
        val base = ctx.getExternalFilesDir(null) ?: ctx.filesDir
        val d = File(base, "export")
        if (!d.exists()) d.mkdirs()
        return d
    }

    fun exportLogCsv(ctx: Context): File {
        val f = File(dir(ctx), "probe-log-${stamp()}.csv")
        f.bufferedWriter().use { w ->
            w.write("time,source,kind,detail\n")
            for (e in ProbeBus.snapshot()) w.write(e.csv() + "\n")
        }
        Log.i(ProbeBus.TAG, "export csv ${f.absolutePath} lines=${ProbeBus.count()}")
        return f
    }

    fun exportLogJson(ctx: Context): File {
        val f = File(dir(ctx), "probe-log-${stamp()}.json")
        val arr = org.json.JSONArray()
        for (e in ProbeBus.snapshot()) {
            val o = org.json.JSONObject()
            o.put("wall", e.wallClock)
            o.put("time", ProbeEvent.timeText(e.wallClock))
            o.put("src", e.src.name)
            o.put("kind", e.kind)
            o.put("detail", e.detail)
            arr.put(o)
        }
        f.writeText(arr.toString(2))
        Log.i(ProbeBus.TAG, "export json ${f.absolutePath}")
        return f
    }

    fun exportReportText(ctx: Context): File {
        val f = File(dir(ctx), "report-${stamp()}.txt")
        f.writeText(CheckRegistry.reportText(ctx))
        return f
    }

    fun exportReportJson(ctx: Context): File {
        val f = File(dir(ctx), "report-${stamp()}.json")
        f.writeText(CheckRegistry.reportJson(ctx))
        return f
    }

    fun share(ctx: Context, file: File) {
        val uri: Uri = Uri.fromFile(file)
        val i = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, file.absolutePath)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        runCatching { ctx.startActivity(Intent.createChooser(i, "导出")) }
    }

    private fun stamp(): String =
        java.text.SimpleDateFormat("yyyyMMdd-HHmmss", java.util.Locale.US).format(java.util.Date())
}
