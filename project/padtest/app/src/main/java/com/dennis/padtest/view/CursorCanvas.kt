package com.dennis.padtest.view

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.util.AttributeSet
import android.view.View
import kotlin.math.abs

/**
 * 光标轨迹画布。
 *
 * 记录最近 [MAX_POINTS] 个指针位置并连线，用于判断：
 * - 指针是否能跟手（轨迹连续、无跳变）；
 * - 落点是否能稳定停在某个像素点（配合下方的网格命中测试）；
 * - 速度变化是否平滑（转折处是否抖动）。
 */
class CursorCanvas @JvmOverloads constructor(
    ctx: Context,
    attrs: AttributeSet? = null,
) : View(ctx, attrs) {

    private val points = ArrayDeque<FloatArray>()
    private val paintTrail = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 2f
        color = 0xFF4FC3F7.toInt()
    }
    private val paintDot = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xFFFF5252.toInt() }
    private val paintGrid = Paint().apply {
        style = Paint.Style.STROKE
        strokeWidth = 1f
        color = 0xFF1B242C.toInt()
    }
    private val paintText = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF7C8B99.toInt()
        textSize = 24f
    }
    private val path = Path()

    var onPointer: ((Float, Float) -> Unit)? = null
    var onClickAt: ((Float, Float) -> Unit)? = null

    fun addPoint(x: Float, y: Float) {
        points.addLast(floatArrayOf(x, y))
        while (points.size > MAX_POINTS) points.removeFirst()
        onPointer?.invoke(x, y)
        invalidate()
    }

    fun markClick(x: Float, y: Float) {
        clickAt = floatArrayOf(x, y)
        onClickAt?.invoke(x, y)
        invalidate()
    }

    fun clearTrail() {
        points.clear()
        clickAt = null
        invalidate()
    }

    fun trailLength(): Float {
        var len = 0f
        var prev: FloatArray? = null
        for (p in points) {
            if (prev != null) len += abs(p[0] - prev!![0]) + abs(p[1] - prev!![1])
            prev = p
        }
        return len
    }

    private var clickAt: FloatArray? = null

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawColor(0xFF0B0F13.toInt())

        // 网格（每 50px 一格，便于肉眼估距离）
        var x = 0f
        while (x < width) {
            canvas.drawLine(x, 0f, x, height.toFloat(), paintGrid)
            x += 50f
        }
        var y = 0f
        while (y < height) {
            canvas.drawLine(0f, y, width.toFloat(), y, paintGrid)
            y += 50f
        }

        if (points.size >= 2) {
            path.reset()
            val first = points.first()
            path.moveTo(first[0], first[1])
            for (p in points.drop(1)) path.lineTo(p[0], p[1])
            canvas.drawPath(path, paintTrail)
        }
        val last = points.lastOrNull()
        if (last != null) {
            canvas.drawCircle(last[0], last[1], 6f, paintDot)
            canvas.drawText(
                "%.0f, %.0f".format(last[0], last[1]),
                (last[0] + 12f).coerceAtMost(width - 140f),
                (last[1] - 12f).coerceAtLeast(24f),
                paintText,
            )
        }
        clickAt?.let {
            paintDot.color = 0xFFFFD740.toInt()
            canvas.drawCircle(it[0], it[1], 12f, paintDot)
            paintDot.color = 0xFFFF5252.toInt()
        }
        canvas.drawText("trail ${points.size} pts   Σ=${trailLength().toInt()}px", 12f, height - 14f, paintText)
    }

    companion object {
        const val MAX_POINTS = 50
    }
}
