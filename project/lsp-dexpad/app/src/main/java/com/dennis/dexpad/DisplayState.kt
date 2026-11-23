package com.dennis.dexpad

import android.content.Context
import android.hardware.display.DisplayManager
import android.view.Display

/**
 * The mapping engine only targets the phone's built-in screen.
 *
 * DeX support was removed: [active] is always the built-in display that is
 * currently on (fold cover or inner panel), and every helper command is sent
 * with that display id.
 */
class DisplayState(context: Context) {
    private val dm = context.getSystemService(DisplayManager::class.java)

    fun active(): Int = phoneDisplay()

    fun isPhone(): Boolean = true

    /** the built-in screen that is currently on (fold cover or inner panel) */
    fun phoneDisplay(): Int {
        val displays = try {
            dm.displays
        } catch (_: Throwable) {
            null
        } ?: return 0
        // FLAG_EXTRA_BUILT_IN_DISPLAY (0x10000000): the cover screen of a foldable
        for (d in displays) {
            val builtIn = d.displayId == Display.DEFAULT_DISPLAY ||
                (d.flags and 0x10000000) != 0
            if (builtIn && d.state == Display.STATE_ON) return d.displayId
        }
        return 0
    }

    /**
     * Current app size of a display: `Display.Mode` is the panel's physical mode
     * and getRealSize ignores `wm size` overrides, while getSize() returns the
     * current app size (it also respects the fold cover/inner switch).
     */
    fun size(id: Int): Pair<Int, Int> {
        val d = dm.getDisplay(id)
        val p = android.graphics.Point()
        try {
            d?.getSize(p)
        } catch (_: Throwable) {
        }
        if (p.x <= 0 || p.y <= 0) {
            try {
                d?.getRealSize(p)
            } catch (_: Throwable) {
            }
        }
        if (p.x > 0 && p.y > 0) return Pair(p.x, p.y)
        val m = d?.mode
        return Pair(m?.physicalWidth ?: 904, m?.physicalHeight ?: 2316)
    }

    fun rotation(id: Int): Int = try {
        dm.getDisplay(id)?.rotation ?: 0
    } catch (_: Throwable) {
        0
    }

    /**
     * 面板物理像素（当前旋转后的宽高）。Samsung 的 display_size_forced 覆盖会让
     * 应用空间（getSize）与物理面板不一致，系统会把画面等比缩放并居中（letterbox）：
     * 指针坐标（dumpsys input）用的是物理空间，点击落点是应用空间，两者必须换算。
     */
    fun physicalSize(id: Int): Pair<Int, Int> {
        val d = dm.getDisplay(id) ?: return Pair(0, 0)
        val m = try {
            d.mode
        } catch (_: Throwable) {
            null
        }
        var w = m?.physicalWidth ?: 0
        var h = m?.physicalHeight ?: 0
        if (w <= 0 || h <= 0) return Pair(0, 0)
        if (d.rotation == 1 || d.rotation == 3) {
            val t = w
            w = h
            h = t
        }
        return Pair(w, h)
    }
}
