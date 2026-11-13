package com.dennis.gamepadmouse

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.ViewConfiguration
import androidx.appcompat.widget.AppCompatSeekBar

/**
 * Kotlin port of the original app's `VerticalFriendlySeekBar`.
 *
 * A drag that starts mostly vertically is handled by the seek bar itself (and
 * the events are swallowed so the surrounding page can not steal them); a drag
 * that is clearly horizontal (more than 1.5x the vertical movement) is handed
 * to the parent - that is what keeps the drawer's edge swipe working while the
 * seek bars live inside a scrolling page.
 */
class VerticalFriendlySeekBar @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = android.R.attr.seekBarStyle,
) : AppCompatSeekBar(context, attrs, defStyleAttr) {

    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var downX = 0f
    private var downY = 0f
    private var verticalDrag = false

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x
                downY = event.y
                verticalDrag = false
            }

            MotionEvent.ACTION_MOVE -> {
                if (!verticalDrag) {
                    val dx = abs(event.x - downX)
                    val dy = abs(event.y - downY)
                    if (dx > touchSlop || dy > touchSlop) {
                        // "vertical friendly": only a clearly horizontal drag escapes
                        verticalDrag = !(dx > dy * 1.5f)
                    }
                }
                if (verticalDrag) return true
            }

            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (verticalDrag) {
                    verticalDrag = false
                    return true
                }
            }
        }
        return super.onTouchEvent(event)
    }

    private fun abs(v: Float): Float = if (v < 0f) -v else v
}
