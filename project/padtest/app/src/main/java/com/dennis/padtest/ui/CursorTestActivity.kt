package com.dennis.padtest.ui

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.ProbeEvent
import com.dennis.padtest.core.Src
import com.dennis.padtest.view.CursorCanvas
import kotlin.math.abs
import kotlin.math.hypot

/**
 * 二、光标测试页。
 *
 * 观察点：
 * - 指针位置 / 轨迹（最近 50 点）；
 * - 速度（px/s，200ms 窗口）；
 * - 点击落点坐标与按键；
 * - 「指针是否在可滚动容器内」（用于验证焦点锚定）；
 * - 200dp × 200dp 的小按钮网格：轻推能否稳定停在单个格子上。
 */
class CursorTestActivity : ProbeActivity() {

    private lateinit var canvas: CursorCanvas
    private lateinit var posText: TextView
    private lateinit var speedText: TextView
    private lateinit var clickText: TextView
    private lateinit var focusText: TextView
    private lateinit var gridText: TextView

    private var lastX = 0f
    private var lastY = 0f
    private var lastAt = 0L
    private var speed = 0f
    private var hoverCount = 0
    private var lastHit = "-"

    private val handler = Handler(Looper.getMainLooper())

    private val decay = object : Runnable {
        override fun run() {
            // 200ms 内没有新移动就把速度归零，避免显示陈旧值
            if (SystemClock.elapsedRealtime() - lastAt > 220) speed = 0f
            speedText.text = "速度 %.0f px/s".format(speed)
            handler.postDelayed(this, 200)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        CheckRegistry.define("CURSOR.MOVE", "光标", "指针可移动")
        CheckRegistry.define("CURSOR.FOCUS", "光标", "指针可落在可滚动容器内")
        CheckRegistry.define("CURSOR.GRID", "光标", "轻推可稳定停在单个小格子")
        super.onCreate(savedInstanceState)
    }

    override fun buildContent(): View {
        val col = page("光标测试", "推左摇杆：看轨迹是否跟手；点小格子：看落点精度")

        posText = mono("pointer -", 12f, 0xFF4FC3F7.toInt())
        speedText = mono("速度 0 px/s", 12f)
        clickText = mono("点击 -", 12f)
        focusText = mono("焦点容器 -", 12f)
        gridText = mono("格子命中 -", 12f)

        col.addView(
            card(
                posText,
                row(speedText, tv("    ", 12f), gridText),
                clickText,
                focusText,
            ),
        )

        canvas = CursorCanvas(this)
        canvas.onPointer = { x, y ->
            val now = SystemClock.elapsedRealtime()
            if (lastAt > 0 && now > lastAt) {
                val dt = (now - lastAt) / 1000f
                val d = hypot((x - lastX).toDouble(), (y - lastY).toDouble()).toFloat()
                // 一阶低通，避免读数跳动
                speed = speed * 0.7f + (d / dt) * 0.3f
            }
            lastX = x; lastY = y; lastAt = now
            hoverCount++
            posText.text = "pointer %.0f, %.0f   (样本 %d)".format(x, y, hoverCount)
            if (hoverCount > 10) CheckRegistry.pass("CURSOR.MOVE", "$hoverCount 个移动样本")
            updateFocusState(x, y)
        }
        canvas.onClickAt = { x, y -> clickText.text = "点击 %.0f, %.0f".format(x, y) }

        val canvasBox = FrameLayout(this).apply {
            addView(canvas, FrameLayout.LayoutParams(MATCH, MATCH))
            setOnClickListener { /* 让空白区域也可点，用于观察点击坐标 */ }
        }
        col.addView(
            canvasBox,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f),
        )

        col.addView(card(tv("小格子网格（200dp × 200dp，8×8）", 12f, Color.WHITE), buildGrid()))
        col.addView(card(tv("可滚动容器（指针移进来才会显示「焦点容器」）", 12f, Color.WHITE), buildScroller()))

        handler.post(decay)
        return col
    }

    private val MATCH = ViewGroup.LayoutParams.MATCH_PARENT

    // ------------------------------------------------- 200dp × 200dp 网格

    private fun buildGrid(): View {
        val side = dp(200)
        val grid = object : LinearLayout(this) {
            override fun onMeasure(w: Int, h: Int) {
                super.onMeasure(
                    MeasureSpec.makeMeasureSpec(side, MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(side, MeasureSpec.EXACTLY),
                )
            }
        }
        grid.orientation = LinearLayout.VERTICAL
        for (r in 0 until 8) {
            val rl = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (c in 0 until 8) {
                val cell = TextView(this).apply {
                    text = ""
                    gravity = Gravity.CENTER
                    setBackgroundColor(if ((r + c) % 2 == 0) 0xFF1B242C.toInt() else 0xFF222D36.toInt())
                    setOnClickListener {
                        lastHit = "($r,$c)"
                        gridText.text = "格子命中 ($r,$c)"
                        CheckRegistry.pass("CURSOR.GRID", "命中 $lastHit")
                    }
                }
                rl.addView(
                    cell,
                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f),
                )
            }
            grid.addView(rl, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        }
        return grid
    }

    private fun buildScroller(): View {
        val list = ScrollView(this)
        val inner = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        for (i in 0 until 30) {
            inner.addView(
                tv("可滚动内容 #$i", 12f, 0xFF9FB0BE.toInt()).apply {
                    setPadding(dp(8), dp(10), dp(8), dp(10))
                },
            )
        }
        list.addView(inner)
        list.layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(140))
        return list
    }

    // ------------------------------------------------- 焦点容器判定

    private fun updateFocusState(x: Float, y: Float) {
        // 把画布内坐标换算成整窗坐标，再询问窗口根视图「这个点落在哪个可滚动容器里」
        val loc = IntArray(2)
        canvas.getLocationInWindow(loc)
        val wx = loc[0] + x
        val wy = loc[1] + y
        val hit = findScrollableAt(window.decorView, wx.toInt(), wy.toInt())
        focusText.text = if (hit != null) "焦点容器 ${hit.javaClass.simpleName}（可滚动）" else "焦点容器 -（不在可滚动控件上）"
        if (hit != null) CheckRegistry.pass("CURSOR.FOCUS", "命中的是 ${hit.javaClass.simpleName}")
    }

    /** 自顶向下找到该点命中的最深子 View，再向上找最近的「可滚动」祖先 */
    private fun findScrollableAt(root: View, x: Int, y: Int): View? {
        var found: View? = null
        fun walk(v: View) {
            if (v.visibility != View.VISIBLE) return
            val r = android.graphics.Rect()
            v.getGlobalVisibleRect(r)
            if (!r.contains(x, y)) return
            if (v is ViewGroup) {
                for (i in 0 until v.childCount) walk(v.getChildAt(i))
            }
            found = v
        }
        walk(root)
        var cur = found
        while (cur != null) {
            if (cur.canScrollVertically(1) || cur.canScrollVertically(-1) ||
                cur.canScrollHorizontally(1) || cur.canScrollHorizontally(-1)
            ) {
                return cur
            }
            cur = cur.parent as? View
        }
        return null
    }

    // ------------------------------------------------- 事件钩子

    override fun onProbeEvent(e: ProbeEvent) {
        when (e.src) {
            Src.MOUSE -> when (e.kind) {
                "hover" -> {
                    val x = e.extra["x"]?.toFloatOrNull()
                    val y = e.extra["y"]?.toFloatOrNull()
                    // 只有落在画布内的点才进轨迹（换算成画布局部坐标）
                    if (x != null && y != null) {
                        val loc = IntArray(2)
                        canvas.getLocationInWindow(loc)
                        val lx = x - loc[0]
                        val ly = y - loc[1]
                        if (lx >= 0 && ly >= 0 && lx <= canvas.width && ly <= canvas.height) {
                            canvas.addPoint(lx, ly)
                        }
                    }
                }
                "click-down" -> {
                    clickText.text = "点击 ${e.detail}"
                    val x = Regex("x=(-?\\d+)").find(e.detail)?.groupValues?.get(1)?.toFloatOrNull()
                    val y = Regex("y=(-?\\d+)").find(e.detail)?.groupValues?.get(1)?.toFloatOrNull()
                    if (x != null && y != null) {
                        val loc = IntArray(2)
                        canvas.getLocationInWindow(loc)
                        canvas.markClick(x - loc[0], y - loc[1])
                    }
                }
            }
            else -> Unit
        }
    }

    override fun onPause() {
        handler.removeCallbacks(decay)
        super.onPause()
    }
}
