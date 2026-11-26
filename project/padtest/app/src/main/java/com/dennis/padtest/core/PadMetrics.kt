package com.dennis.padtest.core

import org.json.JSONObject

/**
 * v1.2 新增埋点（供 v1.69 自动化套件直接读取）：
 * - touch：ACTION_MOVE 帧数/最大间隔/路径/时长（ProbeActivity 在 ACTION_UP 汇总）
 * - scroll：左右两个独立列表的 offset、固定区域收到的滚动尝试次数、纵向/横向容器 offset
 *
 * 只有“确实发生了”才写入；未发生保持 0，套件读到 0 应判 BLOCKED/UNKNOWN，不得伪造 PASS。
 */
object PadMetrics {

    // ---- 触摸 MOVE 连续性（最近一次手势） ----
    @Volatile var touchFrames: Int = 0
    @Volatile var touchMaxGapMs: Long = 0
    @Volatile var touchPathPx: Int = 0
    @Volatile var touchDurMs: Long = 0
    @Volatile var touchDownX: Int = 0
    @Volatile var touchDownY: Int = 0
    @Volatile var touchUpX: Int = 0
    @Volatile var touchUpY: Int = 0
    @Volatile var touchSource: String = ""

    // ---- 滚动容器 ----
    @Volatile var leftOffset: Int = 0
    @Volatile var rightOffset: Int = 0
    @Volatile var fixedAreaScrolls: Int = 0
    @Volatile var fixedAreaWheel: Int = 0
    @Volatile var fixedAreaTouch: Int = 0
    @Volatile var verticalOffset: Int = 0
    @Volatile var horizontalScrollX: Int = 0

    fun reset() {
        touchFrames = 0; touchMaxGapMs = 0; touchPathPx = 0; touchDurMs = 0
        touchDownX = 0; touchDownY = 0; touchUpX = 0; touchUpY = 0; touchSource = ""
        leftOffset = 0; rightOffset = 0
        fixedAreaScrolls = 0; fixedAreaWheel = 0; fixedAreaTouch = 0
        verticalOffset = 0; horizontalScrollX = 0
    }

    fun touchJson(): JSONObject = JSONObject().apply {
        put("frames", touchFrames)
        put("max_gap_ms", touchMaxGapMs)
        put("path_px", touchPathPx)
        put("duration_ms", touchDurMs)
        put("down_x", touchDownX)
        put("down_y", touchDownY)
        put("up_x", touchUpX)
        put("up_y", touchUpY)
        put("source", touchSource)
        put("continuous", touchFrames >= 2 && touchMaxGapMs in 1..40)
    }

    fun scrollJson(): JSONObject = JSONObject().apply {
        put("left_offset", leftOffset)
        put("right_offset", rightOffset)
        put("fixed_area_scrolls", fixedAreaScrolls)
        put("fixed_area_wheel", fixedAreaWheel)
        put("fixed_area_touch", fixedAreaTouch)
        put("vertical_offset", verticalOffset)
        put("horizontal_scroll_x", horizontalScrollX)
        put("sides_independent", leftOffset != rightOffset)
    }

    fun json(): JSONObject = JSONObject().apply {
        put("touch", touchJson())
        put("scroll", scrollJson())
    }
}
