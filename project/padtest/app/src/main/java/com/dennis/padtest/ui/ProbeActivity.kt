package com.dennis.padtest.ui

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.SystemClock
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.dennis.padtest.core.CheckRegistry
import com.dennis.padtest.core.PadMetrics
import com.dennis.padtest.core.ProbeBus
import com.dennis.padtest.core.ProbeEvent
import com.dennis.padtest.core.Src

/**
 * 所有测试页的基类。
 *
 * 职责：
 * 1. 统一捕获按键 / 鼠标 / 触摸 / 滚轮事件，先写总线（含 logcat 镜像），再交给子类；
 * 2. 提供统一的深色页面骨架、卡片、按钮、标题栏；
 * 3. 右上角常驻「日志 / 报告」入口（除日志页自身）。
 *
 * 注意：捕获在 dispatch* 里做，**不消费**事件（返回 super），保证页面控件仍能正常响应，
 * 这样才能同时观察「事件到达」和「控件反应」。
 */
abstract class ProbeActivity : Activity() {

    private var overlay: View? = null
    private val keyDownAt = HashMap<Int, Long>()
    private var downX = 0f
    private var downY = 0f

    // v1.2：ACTION_MOVE 连续性埋点（每次 DOWN→UP 手势）
    private var moveFrames = 0
    private var moveMaxGap = 0L
    private var moveLastAt = 0L
    private var moveLastX = 0f
    private var moveLastY = 0f
    private var movePath = 0f
    private var gestureDownAt = 0L

    protected val pageName: String get() = title?.toString() ?: javaClass.simpleName

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CheckRegistry.define("UI.OPEN.$pageName", pageName, "页面可打开")
        CheckRegistry.pass("UI.OPEN.$pageName")
        CheckRegistry.define("TOUCH.MOVE", "触摸", "ACTION_MOVE 连续帧（帧数/最大间隔）")
        val content = buildContent()
        val root = FrameLayout(this)
        root.addView(
            content,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        overlay = buildOverlay()
        root.addView(
            overlay,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.END or Gravity.TOP,
            ),
        )
        setContentView(root)
    }

    override fun onResume() {
        super.onResume()
        ProbeBus.sample(Src.SYSTEM, "page", "resume $pageName")
        refreshOverlay()
    }

    // ------------------------------------------------------------ 子类实现

    /** 页面主体 */
    protected abstract fun buildContent(): View

    /** 收到任意事件（已在总线上登记过） */
    protected open fun onProbeEvent(e: ProbeEvent) {}

    // v1.2：让子类在 Activity 级观察触摸/滚轮落点（子 View 可能被外层 ScrollView 拦截）
    protected open fun onTouchDownAt(x: Float, y: Float) {}
    protected open fun onTouchEndAt(x: Float, y: Float, frames: Int, path: Float) {}
    protected open fun onWheelAt(x: Float, y: Float) {}

    // ------------------------------------------------------------ 事件捕获

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val name = KeyEvent.keyCodeToString(event.keyCode)
        when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                val prev = keyDownAt.put(event.keyCode, SystemClock.elapsedRealtime())
                val repeat = event.repeatCount
                emit(
                    ProbeEvent(
                        src = Src.KEY,
                        kind = if (repeat == 0) "key-down" else "key-repeat",
                        detail = "$name(${event.keyCode}) repeat=$repeat" +
                            (if (prev != null) " since-up=${SystemClock.elapsedRealtime() - prev}ms" else ""),
                        extra = mapOf("code" to event.keyCode.toString(), "name" to name),
                    ),
                )
            }
            KeyEvent.ACTION_UP -> {
                val down = keyDownAt.remove(event.keyCode)
                val held = if (down != null) SystemClock.elapsedRealtime() - down else -1
                emit(
                    ProbeEvent(
                        src = Src.KEY,
                        kind = "key-up",
                        detail = "$name(${event.keyCode}) held=${held}ms",
                        extra = mapOf("code" to event.keyCode.toString(), "held" to held.toString()),
                    ),
                )
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchGenericMotionEvent(ev: MotionEvent): Boolean {
        val src = ev.source
        val fromMouse = (src and android.view.InputDevice.SOURCE_MOUSE) != 0
        val fromTouchpad = (src and android.view.InputDevice.SOURCE_TOUCHPAD) != 0
        if (fromMouse || fromTouchpad) {
            when (ev.actionMasked) {
                MotionEvent.ACTION_HOVER_MOVE -> emit(
                    ProbeEvent(
                        src = Src.MOUSE,
                        kind = "hover",
                        detail = "x=${ev.x.toInt()} y=${ev.y.toInt()}",
                        extra = mapOf("x" to ev.x.toString(), "y" to ev.y.toString()),
                    ),
                )
                MotionEvent.ACTION_SCROLL -> {
                    val v = ev.getAxisValue(MotionEvent.AXIS_VSCROLL)
                    val h = ev.getAxisValue(MotionEvent.AXIS_HSCROLL)
                    onWheelAt(ev.x, ev.y)
                    emit(
                        ProbeEvent(
                            src = Src.WHEEL,
                            kind = "scroll",
                            detail = "v=$v h=$h",
                            extra = mapOf("v" to v.toString(), "h" to h.toString()),
                        ),
                    )
                }
            }
            val v = ev.getAxisValue(MotionEvent.AXIS_VSCROLL)
            val h = ev.getAxisValue(MotionEvent.AXIS_HSCROLL)
            if (v != 0f || h != 0f) {
                emit(ProbeEvent(src = Src.WHEEL, kind = "scroll-axis", detail = "v=$v h=$h"))
            }
        }
        return super.dispatchGenericMotionEvent(ev)
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        val fromMouse = (ev.source and android.view.InputDevice.SOURCE_MOUSE) != 0
        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = ev.x
                downY = ev.y
                // v1.2: 手势开始，重置 MOVE 统计
                moveFrames = 0
                moveMaxGap = 0L
                movePath = 0f
                moveLastAt = 0L
                moveLastX = ev.x
                moveLastY = ev.y
                gestureDownAt = SystemClock.elapsedRealtime()
                PadMetrics.touchFrames = 0
                PadMetrics.touchMaxGapMs = 0
                PadMetrics.touchPathPx = 0
                PadMetrics.touchDurMs = 0
                PadMetrics.touchDownX = ev.x.toInt()
                PadMetrics.touchDownY = ev.y.toInt()
                PadMetrics.touchSource = if (fromMouse) "mouse" else "touch"
                onTouchDownAt(ev.x, ev.y)
                emit(
                    ProbeEvent(
                        src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                        kind = if (fromMouse) "click-down" else "touch-down",
                        detail = "x=${ev.x.toInt()} y=${ev.y.toInt()} btn=${ev.buttonState}",
                    ),
                )
            }
            MotionEvent.ACTION_MOVE -> {
                // v1.2: 逐帧记录 MOVE（只累计，不逐帧刷总线，避免高频日志淹没）
                val now = SystemClock.elapsedRealtime()
                moveFrames++
                if (moveLastAt > 0L) {
                    val gap = now - moveLastAt
                    if (gap > moveMaxGap) moveMaxGap = gap
                }
                movePath += kotlin.math.hypot((ev.x - moveLastX).toDouble(), (ev.y - moveLastY).toDouble()).toFloat()
                moveLastAt = now
                moveLastX = ev.x
                moveLastY = ev.y
                PadMetrics.touchFrames = moveFrames
                PadMetrics.touchMaxGapMs = moveMaxGap
                PadMetrics.touchPathPx = movePath.toInt()
                PadMetrics.touchDurMs = now - gestureDownAt
                if (moveFrames % 40 == 0) {
                    emit(
                        ProbeEvent(
                            src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                            kind = "move-heartbeat",
                            detail = "frames=$moveFrames maxGap=${moveMaxGap}ms path=${movePath.toInt()}px",
                            extra = mapOf("frames" to moveFrames.toString(), "maxGap" to moveMaxGap.toString()),
                        ),
                    )
                }
            }
            MotionEvent.ACTION_UP -> {
                val dx = ev.x - downX
                val dy = ev.y - downY
                val dist = kotlin.math.hypot(dx.toDouble(), dy.toDouble()).toFloat()
                val moved = dist > 40f
                val dur = SystemClock.elapsedRealtime() - gestureDownAt
                // v1.2: 手势结束写摘要 + 判定（帧数 ≥2 且最大间隔 ≤40ms 才算连续）
                PadMetrics.touchFrames = moveFrames
                PadMetrics.touchMaxGapMs = moveMaxGap
                PadMetrics.touchPathPx = movePath.toInt()
                PadMetrics.touchDurMs = dur
                PadMetrics.touchUpX = ev.x.toInt()
                PadMetrics.touchUpY = ev.y.toInt()
                onTouchEndAt(ev.x, ev.y, moveFrames, movePath)
                emit(
                    ProbeEvent(
                        src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                        kind = "touch-move-summary",
                        detail = "frames=$moveFrames maxGap=${moveMaxGap}ms path=${movePath.toInt()}px dur=${dur}ms",
                        extra = mapOf(
                            "frames" to moveFrames.toString(),
                            "maxGap" to moveMaxGap.toString(),
                            "path" to movePath.toInt().toString(),
                            "dur" to dur.toString(),
                        ),
                    ),
                )
                when {
                    moveFrames >= 2 && moveMaxGap in 1..40 ->
                        CheckRegistry.pass("TOUCH.MOVE", "frames=$moveFrames maxGap=${moveMaxGap}ms")
                    moveFrames >= 2 ->
                        CheckRegistry.fail("TOUCH.MOVE", "frames=$moveFrames maxGap=${moveMaxGap}ms >40ms")
                    else ->
                        CheckRegistry.unknown("TOUCH.MOVE", "frames=$moveFrames（单击/无 MOVE）")
                }
                emit(
                    ProbeEvent(
                        src = if (fromMouse) Src.MOUSE else Src.TOUCH,
                        kind = if (moved) "drag" else if (fromMouse) "click-up" else "touch-up",
                        detail = "x=${ev.x.toInt()} y=${ev.y.toInt()} dx=${dx.toInt()} dy=${dy.toInt()} dist=${dist.toInt()}",
                        extra = mapOf("dx" to dx.toString(), "dy" to dy.toString(), "dist" to dist.toString()),
                    ),
                )
                // 位移足够大时额外记一条「手势滑动」，方便与滚轮后端区分
                if (moved) {
                    emit(
                        ProbeEvent(
                            src = Src.TOUCH,
                            kind = "swipe",
                            detail = "dx=${dx.toInt()} dy=${dy.toInt()} dist=${dist.toInt()}",
                            extra = mapOf("dx" to dx.toString(), "dy" to dy.toString()),
                        ),
                    )
                }
            }
        }
        return super.dispatchTouchEvent(ev)
    }

    private fun emit(e: ProbeEvent) {
        ProbeBus.post(e)
        onProbeEvent(e)
    }

    // ------------------------------------------------------------ 通用 UI

    protected fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    protected fun sp(v: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, resources.displayMetrics)

    protected fun tv(text: String = "", size: Float = 14f, color: Int = 0xFFE0E0E0.toInt()): TextView =
        TextView(this).apply {
            this.text = text
            setTextColor(color)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
        }

    protected fun mono(text: String = "", size: Float = 12f, color: Int = 0xFF80CBC4.toInt()): TextView =
        tv(text, size, color).apply { typeface = Typeface.MONOSPACE }

    protected fun button(label: String, onClick: () -> Unit): Button =
        Button(this).apply {
            text = label
            setOnClickListener { onClick() }
        }

    protected fun page(titleText: String, subtitle: String? = null): LinearLayout {
        title = titleText
        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), dp(14), dp(14), dp(24))
        }
        col.addView(tv(titleText, 20f, Color.WHITE).apply { typeface = Typeface.DEFAULT_BOLD })
        if (subtitle != null) col.addView(tv(subtitle, 12f, 0xFF8FA0B0.toInt()).apply {
            setPadding(0, dp(3), 0, dp(8))
        })
        return col
    }

    protected fun card(vararg children: View): LinearLayout {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            background = android.graphics.drawable.GradientDrawable().apply {
                cornerRadius = dp(10).toFloat()
                setColor(0xFF161C22.toInt())
                setStroke(dp(1), 0xFF24303A.toInt())
            }
        }
        for (c in children) {
            box.addView(
                c,
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ).apply { topMargin = dp(3); bottomMargin = dp(3) },
            )
        }
        val wrap = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(6), 0, dp(6))
            addView(box)
        }
        return wrap
    }

    /** 卡片标题 + 内容两行 */
    protected fun kv(label: String, valueView: View): LinearLayout {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(2), 0, dp(2))
        }
        row.addView(tv(label, 11f, 0xFF7C8B99.toInt()))
        row.addView(valueView)
        return row
    }

    protected fun scroll(child: View): ScrollView = ScrollView(this).apply { addView(child) }

    protected fun row(vararg children: View): LinearLayout {
        val r = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        for (c in children) r.addView(c)
        return r
    }

    // ------------------------------------------------------------ 悬浮入口

    private var logButton: Button? = null

    private fun buildOverlay(): View {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(8), dp(8), dp(8), 0)
            alpha = 0.86f
        }
        if (this !is LogActivity) {
            box.addView(button("日志") { startActivity(Intent(this, LogActivity::class.java)) }.apply {
                textSize = 11f
                minHeight = 0
                setPadding(dp(10), 0, dp(10), 0)
                logButton = this
            })
        }
        if (this !is ReportActivity) {
            box.addView(button("报告") { startActivity(Intent(this, ReportActivity::class.java)) }.apply {
                textSize = 11f
                minHeight = 0
                setPadding(dp(10), 0, dp(10), 0)
            })
        }
        return box
    }

    protected fun refreshOverlay() {
        val n = ProbeBus.count()
        logButton?.text = "日志 $n"
    }
}
