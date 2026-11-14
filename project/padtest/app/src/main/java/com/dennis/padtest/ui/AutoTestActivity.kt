package com.dennis.padtest.ui

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject
import java.io.File

/**
 * 自动化测试专用页面（给 adb 脚本用）。
 *
 * 这个页面自己判断"手柄动作有没有真的生效"，并把结果写进 JSON：
 *   /sdcard/Android/data/com.dennis.padtest/files/auto-report.json
 * 这样测试脚本不需要去 grep logcat/助手日志，直接 pull 报告即可。
 *
 * 覆盖的检查项：
 *  T1 指针移动     —— 收到 hover 且坐标发生变化
 *  T2 鼠标点击     —— 收到 click-down + click-up
 *  T3 长按         —— 按下到抬起 >= 600ms
 *  T4 方向键焦点   —— 收到 DPAD_* 且焦点索引发生变化
 *  T5 滚动         —— 触摸拖动让 scrollY 双向变化（向上/向下各一次）
 *  T6 双指缩放     —— 双指距离变化 >= 5%
 *  T7 键盘组合     —— 收到 Ctrl + PLUS / MINUS
 *  T8 返回键       —— 收到 KEYCODE_BACK
 *  T9 触摸点击     —— 收到真实触摸 ACTION_DOWN/UP（用于验证"触摸点击"模式）
 */
class AutoTestActivity : Activity() {

    private lateinit var statusRows: MutableMap<String, TextView>
    private lateinit var scroll: ScrollView
    private lateinit var clickArea: TextView

    private var hoverSeen = false
    private var hoverX = 0f
    private var hoverY = 0f
    private var hoverMoved = false
    private var clickDown = false
    private var clickUp = false
    private var clickInside = false
    private var pressStart = 0L
    private var longPress = false
    private var dpadSeen = false
    private var focusMoves = 0
    private var lastFocus = -1
    private var scrollMin = Int.MAX_VALUE
    private var scrollMax = Int.MIN_VALUE
    private var scrollUpSeen = false
    private var scrollDownSeen = false
    private var pinchStartDist = 0f
    private var pinchSeen = false
    private var keyComboSeen = false
    private var backSeen = false
    private var touchDownSeen = false
    private var confirmSeen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        statusRows = LinkedHashMap()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF101418.toInt())
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }

        root.addView(TextView(this).apply {
            text = "自动化测试台（adb 驱动）"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
        })
        root.addView(TextView(this).apply {
            text = "结果写入 files/auto-report.json；手柄动作由 adb 脚本注入"
            setTextColor(0xFF8AB4F8.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        })

        // 可滚动区域：方向键焦点 + 滚动检测
        scroll = ScrollView(this).apply {
            isFocusable = true
            isFocusableInTouchMode = true
        }
        val inner = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        // 大点击区（鼠标/触摸点击检测）
        clickArea = TextView(this).apply {
            text = "点击区（把光标放到这里后按 A）"
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setBackgroundColor(0xFF203040.toInt())
            setPadding(dp(12), dp(80), dp(12), dp(80))
        }
        inner.addView(clickArea, LinearLayout.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)

        // 可获取焦点的按钮（方向键导航检测）
        for (i in 0 until 8) {
            val b = Button(this).apply {
                text = "焦点项 $i"
                isFocusable = true
                isFocusableInTouchMode = true
                setOnClickListener { confirmSeen = true; pushReport(); refreshStatus() }
                setOnFocusChangeListener { _, hasFocus ->
                    if (hasFocus) {
                        if (lastFocus != i) {
                            focusMoves++
                            lastFocus = i
                        }
                        pushReport()
                    }
                }
            }
            inner.addView(b, LinearLayout.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        // 撑高内容，确保可滚动
        inner.addView(View(this), LinearLayout.LayoutParams.MATCH_PARENT, dp(1600))
        scroll.addView(inner)
        root.addView(
            scroll,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f,
            ),
        )

        // 状态列表
        for (k in listOf("T1 指针移动", "T2 鼠标点击", "T3 长按", "T4 方向键焦点", "T5 滚动", "T6 双指缩放", "T7 键盘组合", "T8 返回键", "T9 触摸点击", "T10 方向键确认")) {
            val tv = TextView(this).apply {
                text = "…  $k"
                setTextColor(0xFF7A7A7A.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            }
            statusRows[k] = tv
            root.addView(tv)
        }

        val export = Button(this).apply {
            text = "导出报告"
            setOnClickListener { pushReport(); refreshStatus() }
        }
        root.addView(export)
        setContentView(root)

        scroll.setOnScrollChangeListener { _, _, _, _, _ ->
            onScrollChanged()
        }
        pushReport()
    }

    private fun onScrollChanged() {
        val y = scroll.scrollY
        if (scrollMin == Int.MAX_VALUE) {
            scrollMin = y; scrollMax = y
        }
        if (y < scrollMin) { scrollMin = y; scrollDownSeen = true; pushReport() }
        if (y > scrollMax) { scrollMax = y; scrollUpSeen = true; pushReport() }
        refreshStatus()
    }

    // ---------------------------------------------------------------- 事件捕获
    override fun dispatchGenericMotionEvent(ev: MotionEvent): Boolean {
        val fromMouse = (ev.source and android.view.InputDevice.SOURCE_MOUSE) != 0
        if (fromMouse && ev.actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
            if (!hoverSeen) {
                hoverSeen = true
                hoverX = ev.x; hoverY = ev.y
            } else if (Math.abs(ev.x - hoverX) > 4 || Math.abs(ev.y - hoverY) > 4) {
                hoverMoved = true
                hoverX = ev.x; hoverY = ev.y
            }
            pushReport(); refreshStatus()
        }
        return super.dispatchGenericMotionEvent(ev)
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        val fromMouse = (ev.source and android.view.InputDevice.SOURCE_MOUSE) != 0
        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                if (fromMouse) {
                    clickDown = true
                    pressStart = System.currentTimeMillis()
                } else {
                    touchDownSeen = true
                }
                pushReport(); refreshStatus()
            }
            MotionEvent.ACTION_POINTER_DOWN -> {
                if (ev.pointerCount >= 2) {
                    pinchStartDist = dist(ev)
                }
            }
            MotionEvent.ACTION_MOVE -> {
                if (ev.pointerCount >= 2) {
                    val d = dist(ev)
                    if (pinchStartDist > 0 && Math.abs(d - pinchStartDist) / pinchStartDist > 0.05f) {
                        pinchSeen = true
                        pushReport()
                    }
                }
            }
            MotionEvent.ACTION_UP -> {
                if (fromMouse) {
                    clickUp = true
                    if (pressStart > 0 && System.currentTimeMillis() - pressStart >= 600) longPress = true
                }
                pushReport(); refreshStatus()
            }
        }
        return super.dispatchTouchEvent(ev)
    }

    private fun dist(ev: MotionEvent): Float {
        if (ev.pointerCount < 2) return 0f
        val dx = ev.getX(0) - ev.getX(1)
        val dy = ev.getY(0) - ev.getY(1)
        return Math.hypot(dx.toDouble(), dy.toDouble()).toFloat()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val kc = event.keyCode
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (kc) {
                KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN,
                KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_DPAD_RIGHT -> {
                    dpadSeen = true
                    pushReport(); refreshStatus()
                }
                KeyEvent.KEYCODE_PLUS, KeyEvent.KEYCODE_MINUS -> {
                    if (event.isCtrlPressed) {
                        keyComboSeen = true
                        pushReport(); refreshStatus()
                    }
                }
                KeyEvent.KEYCODE_BACK -> {
                    backSeen = true
                    pushReport(); refreshStatus()
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    // ---------------------------------------------------------------- 状态/报告
    private fun results(): Map<String, Boolean> = linkedMapOf(
        "T1 指针移动" to hoverMoved,
        "T2 鼠标点击" to (clickDown && clickUp),
        "T3 长按" to longPress,
        "T4 方向键焦点" to (dpadSeen && focusMoves >= 2),
        "T5 滚动" to (scrollUpSeen && scrollDownSeen),
        "T6 双指缩放" to pinchSeen,
        "T7 键盘组合" to keyComboSeen,
        "T8 返回键" to backSeen,
        "T9 触摸点击" to touchDownSeen,
        "T10 方向键确认" to (dpadSeen && confirmSeen),
    )

    private fun refreshStatus() {
        for ((k, tv) in statusRows) {
            val ok = results()[k] == true
            tv.text = (if (ok) "✓ " else "…  ") + k
            tv.setTextColor(if (ok) 0xFF34A853.toInt() else 0xFF7A7A7A.toInt())
        }
    }

    private fun pushReport() {
        try {
            val o = JSONObject()
            o.put("wall", System.currentTimeMillis())
            val r = results()
            for ((k, v) in r) o.put(k, v)
            var pass = 0
            for ((_, v) in r) if (v) pass++
            o.put("pass", pass)
            o.put("total", r.size)
            o.put("hoverMoved", hoverMoved)
            o.put("focusMoves", focusMoves)
            o.put("scrollRange", "$scrollMin..$scrollMax")
            val base = getExternalFilesDir(null) ?: filesDir
            for (name in listOf("auto-report.json", "auto-report-latest.json")) {
                File(base, name).writeText(o.toString(2))
            }
            Log.i("PadProbe", "AUTO/${o.getString("pass")}-${o.getInt("total")} " + o.toString())
        } catch (t: Throwable) {
            Log.w("PadProbe", "auto report failed: ${t.message}")
        }
    }

    override fun onPause() {
        // 返回键会结束这个页面：退出前再写一次报告，保证 adb 能拿到 T8
        pushReport()
        super.onPause()
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()
}
