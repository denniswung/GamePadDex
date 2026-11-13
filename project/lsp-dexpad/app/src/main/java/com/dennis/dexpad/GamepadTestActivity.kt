package com.dennis.dexpad

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.SystemClock
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

/**
 * 手柄功能测试页.
 *
 * The engine grabs the physical pad and re-injects mouse/key events, so this
 * activity observes exactly what the mapping produced: clicks, wheel steps,
 * key presses, hover movement and drags. Every observation is also written to
 * logcat with the `GpTest` tag so the adb suites can assert on it.
 */
class GamepadTestActivity : android.app.Activity() {

    private lateinit var pointerView: TextView
    private lateinit var countersView: TextView
    private lateinit var logView: TextView
    private lateinit var grid: LinearLayout

    private val counts = LinkedHashMap<String, Int>()
    private val lines = ArrayDeque<String>()
    private var lastX = -1f
    private var lastY = -1f
    private var movedX = 0f
    private var movedY = 0f
    private var lastKeyAt = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildUi())
        Log.i(TAG, "test activity ready")
    }

    override fun onResume() {
        super.onResume()
        window?.decorView?.requestFocus()
    }

    // ---------------------------------------------------------------- UI

    private fun buildUi(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#101418"))
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }

        val title = TextView(this).apply {
            text = "手柄映射测试页"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setTypeface(typeface, Typeface.BOLD)
        }
        root.addView(title)

        val hint = TextView(this).apply {
            text = "观察映射结果：点击 / 滚轮 / 按键 / 指针移动。每项都会计数并写日志（tag GpTest）。"
            setTextColor(Color.parseColor("#8FA0B0"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setPadding(0, dp(4), 0, dp(10))
        }
        root.addView(hint)

        pointerView = TextView(this).apply {
            setTextColor(Color.parseColor("#4FC3F7"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            text = "pointer  -"
        }
        root.addView(pointerView)

        countersView = TextView(this).apply {
            setTextColor(Color.parseColor("#B0BEC5"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(0, dp(6), 0, dp(6))
            text = "点击 0 · 滚轮 0 · 按键 0 · 拖动 0 px"
        }
        root.addView(countersView)

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.START
        }
        actions.addView(button("清零") { resetCounters() })
        actions.addView(button("聚焦窗口") {
            window?.decorView?.requestFocus()
            log("refocus")
        })
        root.addView(actions)

        grid = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(10), 0, dp(10))
        }
        root.addView(grid)

        logView = TextView(this).apply {
            setTextColor(Color.parseColor("#80CBC4"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.MONOSPACE
            text = ""
        }
        root.addView(
            ScrollView(this).apply {
                addView(logView)
            },
        )
        return ScrollView(this).apply { addView(root) }
    }

    private fun button(label: String, onClick: () -> Unit): Button =
        Button(this).apply {
            text = label
            setOnClickListener { onClick() }
        }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    // ---------------------------------------------------------------- events

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val what = KeyEvent.keyCodeToString(event.keyCode)
        when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                lastKeyAt = SystemClock.elapsedRealtime()
                bump("key:$what")
                log("key down $what (${event.keyCode})")
                Log.i(TAG, "key down code=${event.keyCode} name=$what count=${counts["key:$what"]}")
            }
            KeyEvent.ACTION_UP -> {
                val held = SystemClock.elapsedRealtime() - lastKeyAt
                log("key up   $what after ${held}ms")
                Log.i(TAG, "key up code=${event.keyCode} held=${held}ms")
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchGenericMotionEvent(ev: MotionEvent): Boolean {
        val src = ev.source
        if ((src and android.view.InputDevice.SOURCE_MOUSE) != 0) {
            when (ev.actionMasked) {
                MotionEvent.ACTION_HOVER_MOVE -> {
                    val dx = ev.x - lastX
                    val dy = ev.y - lastY
                    if (lastX >= 0) {
                        movedX += kotlin.math.abs(dx)
                        movedY += kotlin.math.abs(dy)
                    }
                    lastX = ev.x
                    lastY = ev.y
                    pointerView.text = "pointer  %.0f, %.0f   Σ|dx|=%.0f Σ|dy|=%.0f"
                        .format(ev.x, ev.y, movedX, movedY)
                    val vs = ev.getAxisValue(MotionEvent.AXIS_VSCROLL)
                    val hs = ev.getAxisValue(MotionEvent.AXIS_HSCROLL)
                    if (vs != 0f || hs != 0f) {
                        bump("wheel")
                        log("wheel v=$vs h=$hs")
                        Log.i(TAG, "scroll v=$vs h=$hs count=${counts["wheel"]}")
                    }
                }
                MotionEvent.ACTION_SCROLL -> {
                    val vs = ev.getAxisValue(MotionEvent.AXIS_VSCROLL)
                    val hs = ev.getAxisValue(MotionEvent.AXIS_HSCROLL)
                    bump("scroll")
                    log("scroll v=$vs h=$hs")
                    Log.i(TAG, "scroll v=$vs h=$hs count=${counts["scroll"]}")
                }
            }
        }
        if (ev.actionMasked == MotionEvent.ACTION_MOVE || ev.actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
            if (lastX < 0) {
                lastX = ev.x
                lastY = ev.y
            }
        }
        return super.dispatchGenericMotionEvent(ev)
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        val src = ev.source
        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                val btn = if ((src and android.view.InputDevice.SOURCE_MOUSE) != 0) {
                    "click"
                } else {
                    "touch"
                }
                bump(btn)
                log("$btn down at %.0f,%.0f".format(ev.x, ev.y))
                Log.i(TAG, "$btn down x=${ev.x.toInt()} y=${ev.y.toInt()} count=${counts[btn]}")
            }
            MotionEvent.ACTION_UP -> {
                log("up at %.0f,%.0f".format(ev.x, ev.y))
                Log.i(TAG, "up x=${ev.x.toInt()} y=${ev.y.toInt()}")
            }
            MotionEvent.ACTION_MOVE -> {
                bump("drag")
            }
        }
        return super.dispatchTouchEvent(ev)
    }

    // ---------------------------------------------------------------- state

    private fun resetCounters() {
        counts.clear()
        movedX = 0f
        movedY = 0f
        lines.clear()
        logView.text = ""
        refresh()
        Log.i(TAG, "counters reset")
    }

    private fun bump(key: String) {
        counts[key] = (counts[key] ?: 0) + 1
        refresh()
    }

    private fun log(line: String) {
        lines.addLast("%d %s".format(SystemClock.elapsedRealtime() % 100000, line))
        while (lines.size > 14) lines.removeFirst()
        logView.text = lines.joinToString("\n")
    }

    private fun refresh() {
        val clicks = counts["click"] ?: 0
        val scrolls = (counts["wheel"] ?: 0) + (counts["scroll"] ?: 0)
        val keys = counts.entries.filter { it.key.startsWith("key:") }.sumOf { it.value }
        val drag = counts["drag"] ?: 0
        countersView.text = "点击 $clicks · 滚轮 $scrolls · 按键 $keys · 拖动 $drag"
        grid.removeAllViews()
        for ((k, v) in counts.entries.sortedBy { it.key }) {
            grid.addView(
                TextView(this).apply {
                    text = "$k = $v"
                    setTextColor(Color.parseColor("#E0E0E0"))
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    typeface = Typeface.MONOSPACE
                },
            )
        }
    }

    companion object {
        private const val TAG = "GpTest"
    }
}
