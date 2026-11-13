package com.dennis.padtest.ui

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.BaseAdapter
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import com.dennis.padtest.core.Exporter
import com.dennis.padtest.core.ProbeBus
import com.dennis.padtest.core.ProbeEvent
import com.dennis.padtest.core.Src

/**
 * 六、日志面板。
 *
 * 展示「时间戳 / 来源 / 类型 / 参数」，来源用颜色区分（鼠标蓝、滚轮黄、触摸绿、按键白）。
 * 支持：按来源过滤、暂停滚动、清空、导出 CSV/JSON。
 * 每条日志都是「App 接收」这一段的原始记录；控件响应在各自页面上另见，
 * 二者对照即可判断链路断点（收到事件但控件不动 → 事件被吞/坐标错；没收到 → 注入或分发问题）。
 */
class LogActivity : ProbeActivity() {

    private lateinit var list: ListView
    private lateinit var adapter: LogAdapter
    private lateinit var countView: TextView
    private var filter: Src? = null
    private var paused = false
    private val handler = Handler(Looper.getMainLooper())

    private var lastCount = -1

    private val refresh = object : Runnable {
        override fun run() {
            // 只在有新事件时才刷新：界面保持静止，uiautomator dump 才不会因为
            // “永不空闲”而失败（自动化测试需要能读到这里按钮的文字）
            val n = ProbeBus.count()
            if (!paused && n != lastCount) {
                lastCount = n
                adapter.reload()
            }
            val text = "共 $n 条" + if (paused) "（已暂停）" else ""
            if (countView.text != text) countView.text = text
            handler.postDelayed(this, 400)
        }
    }

    override fun buildContent(): View {
        val col = page("事件日志", "时间 / 来源 / 类型 / 参数")

        val bar = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        bar.addView(button("全部") { filter = null; adapter.reload() })
        bar.addView(button("鼠标") { filter = Src.MOUSE; adapter.reload() })
        bar.addView(button("滚轮") { filter = Src.WHEEL; adapter.reload() })
        bar.addView(button("触摸") { filter = Src.TOUCH; adapter.reload() })
        bar.addView(button("按键") { filter = Src.KEY; adapter.reload() })
        col.addView(bar)

        val bar2 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        bar2.addView(button(if (paused) "继续" else "暂停") {
            paused = !paused
        })
        bar2.addView(button("清空") {
            ProbeBus.clear()
            adapter.reload()
        })
        bar2.addView(button("导出 CSV") {
            val f = Exporter.exportLogCsv(this)
            countView.text = "已导出 ${f.absolutePath}"
        })
        bar2.addView(button("导出 JSON") {
            val f = Exporter.exportLogJson(this)
            countView.text = "已导出 ${f.absolutePath}"
        })
        col.addView(bar2)

        countView = mono("共 0 条", 11f, 0xFF7C8B99.toInt())
        col.addView(countView)

        list = ListView(this)
        adapter = LogAdapter()
        list.adapter = adapter
        col.addView(list, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        return col
    }

    private inner class LogAdapter : BaseAdapter() {
        private var items: List<ProbeEvent> = emptyList()

        fun reload() {
            val all = ProbeBus.snapshot()
            items = if (filter == null) all else all.filter { it.src == filter }
            if (items.size > 400) items = items.subList(items.size - 400, items.size)
            notifyDataSetChanged()
            if (!paused) list.setSelection(items.size - 1)
        }

        override fun getCount() = items.size
        override fun getItem(position: Int) = items[position]
        override fun getItemId(position: Int) = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val e = items[position]
            val tv = (convertView as? TextView) ?: TextView(this@LogActivity).apply {
                typeface = android.graphics.Typeface.MONOSPACE
                textSize = 11f
                setPadding(8, 6, 8, 6)
                gravity = Gravity.START
            }
            tv.text = "%s  %-2s %-11s %s".format(
                ProbeEvent.timeText(e.wallClock).substring(3),
                e.src.label,
                e.kind,
                e.detail,
            )
            tv.setTextColor(
                when (e.src) {
                    Src.MOUSE -> 0xFF4FC3F7.toInt()
                    Src.WHEEL -> 0xFFFFD740.toInt()
                    Src.TOUCH -> 0xFF69F0AE.toInt()
                    Src.KEY -> 0xFFE0E0E0.toInt()
                    Src.SYSTEM -> 0xFF9FB0BE.toInt()
                },
            )
            return tv
        }
    }

    override fun onResume() {
        super.onResume()
        adapter.reload()
        handler.post(refresh)
    }

    override fun onPause() {
        handler.removeCallbacks(refresh)
        super.onPause()
    }
}
