package com.dennis.padtest.view

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.SystemClock
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.abs

/**
 * 同时可纵向/横向滚动的容器，用来验证「轴向锁定」：
 * - 触摸拖动：一次手势只允许一个方向（先超过阈值的方向胜出，直到抬手）；
 * - 滚轮：每次滚动事件按主轴锁定 400ms，避免斜滚时来回抖。
 *
 * 不依赖 ScrollView：内部自己维护偏移量并直接绘制，方便精确报告 px/s 与锁定轴。
 */
class AxisLockView @JvmOverloads constructor(
    ctx: Context,
    attrs: AttributeSet? = null,
) : View(ctx, attrs) {

    data class State(
        val offsetX: Float,
        val offsetY: Float,
        val axis: Int,       // 0 无, 1 横向, 2 纵向
        val velocity: Float, // px/s（主轴）
        val contentW: Int,
        val contentH: Int,
    )

    var onState: ((State) -> Unit)? = null

    private val contentW = 3200
    private val contentH = 3200
    private var ox = 0f
    private var oy = 0f
    private var lockedAxis = 0
    private var lockUntil = 0L

    private var downX = 0f
    private var downY = 0f
    private var lastX = 0f
    private var lastY = 0f
    private var lastT = 0L
    private var velocity = 0f

    private val paintGrid = Paint().apply {
        style = Paint.Style.STROKE
        strokeWidth = 1f
        color = 0xFF1B242C.toInt()
    }
    private val paintMajor = Paint().apply {
        style = Paint.Style.STROKE
        strokeWidth = 2f
        color = 0xFF2E3B47.toInt()
    }
    private val paintText = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF9FB0BE.toInt()
        textSize = 28f
    }

    override fun onTouchEvent(ev: MotionEvent): Boolean {
        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = ev.x; downY = ev.y
                lastX = ev.x; lastY = ev.y
                lastT = SystemClock.elapsedRealtime()
                lockedAxis = 0
                velocity = 0f
                parent?.requestDisallowInterceptTouchEvent(true)
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val totalDx = ev.x - downX
                val totalDy = ev.y - downY
                if (lockedAxis == 0 && (abs(totalDx) > 8f || abs(totalDy) > 8f)) {
                    lockedAxis = if (abs(totalDx) >= abs(totalDy)) 1 else 2
                }
                val dx = ev.x - lastX
                val dy = ev.y - lastY
                val now = SystemClock.elapsedRealtime()
                val dt = ((now - lastT).coerceAtLeast(1)) / 1000f
                lastX = ev.x; lastY = ev.y; lastT = now

                when (lockedAxis) {
                    1 -> {
                        ox = (ox - dx).coerceIn(0f, (contentW - width).toFloat().coerceAtLeast(0f))
                        velocity = abs(dx) / dt
                    }
                    2 -> {
                        oy = (oy - dy).coerceIn(0f, (contentH - height).toFloat().coerceAtLeast(0f))
                        velocity = abs(dy) / dt
                    }
                    else -> {}
                }
                invalidate()
                publish()
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                parent?.requestDisallowInterceptTouchEvent(false)
                velocity = 0f
                publish()
                return true
            }
        }
        return super.onTouchEvent(ev)
    }

    override fun onGenericMotionEvent(ev: MotionEvent): Boolean {
        if (ev.actionMasked == MotionEvent.ACTION_SCROLL) {
            val v = ev.getAxisValue(MotionEvent.AXIS_VSCROLL)
            val h = ev.getAxisValue(MotionEvent.AXIS_HSCROLL)
            if (v == 0f && h == 0f) return false
            val now = SystemClock.elapsedRealtime()
            if (now > lockUntil) {
                lockedAxis = if (abs(h) >= abs(v)) 1 else 2
                lockUntil = now + 400
            }
            val step = 90f
            when (lockedAxis) {
                1 -> ox = (ox - h * step).coerceIn(0f, (contentW - width).toFloat().coerceAtLeast(0f))
                2 -> oy = (oy - v * step).coerceIn(0f, (contentH - height).toFloat().coerceAtLeast(0f))
            }
            velocity = abs((if (lockedAxis == 1) h else v) * step) * 10f
            invalidate()
            publish()
            return true
        }
        return super.onGenericMotionEvent(ev)
    }

    private fun publish() {
        onState?.invoke(
            State(
                offsetX = ox,
                offsetY = oy,
                axis = lockedAxis,
                velocity = velocity,
                contentW = contentW,
                contentH = contentH,
            ),
        )
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawColor(0xFF0B0F13.toInt())
        val step = 100f
        var gx = -(ox % step)
        while (gx < width) {
            canvas.drawLine(gx, 0f, gx, height.toFloat(), paintGrid)
            gx += step
        }
        var gy = -(oy % step)
        while (gy < height) {
            canvas.drawLine(0f, gy, width.toFloat(), gy, paintGrid)
            gy += step
        }
        // 内容坐标轴
        canvas.drawLine(-ox, 0f, -ox, height.toFloat(), paintMajor)
        canvas.drawLine(0f, -oy, width.toFloat(), -oy, paintMajor)

        val axisName = when (lockedAxis) {
            1 -> "锁定：横向"
            2 -> "锁定：纵向"
            else -> "锁定：无"
        }
        canvas.drawText("offset %.0f, %.0f".format(ox, oy), 20f, 40f, paintText)
        canvas.drawText(axisName, 20f, 80f, paintText)
        canvas.drawText("v=%.0f px/s".format(velocity), 20f, 120f, paintText)
        canvas.drawText("content %d×%d".format(contentW, contentH), 20f, 160f, paintText)
    }
}
