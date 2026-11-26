package com.dennis.padtest.view

import android.content.Context
import android.util.AttributeSet
import android.widget.ScrollView

/**
 * v1.2：外层页面滚动容器。
 *
 * 默认 ScrollView 会在超过 touch slop 后拦截所有纵向拖动，导致内嵌的
 * 左右两个独立列表永远收不到滚动（探针测不到“只滚一侧”）。
 * 这里允许业务指定“命中这些区域时不拦截”，把事件留给子列表。
 */
class PassThroughScrollView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : ScrollView(context, attrs) {

    /** 返回 true 时，本次手势不被外层拦截（交给子 View） */
    var passThrough: (Float, Float) -> Boolean = { _, _ -> false }
    private var pass = false

    override fun onInterceptTouchEvent(ev: android.view.MotionEvent): Boolean {
        if (ev.actionMasked == android.view.MotionEvent.ACTION_DOWN) {
            pass = passThrough(ev.x, ev.y)
        }
        if (pass) return false
        return super.onInterceptTouchEvent(ev)
    }
}
