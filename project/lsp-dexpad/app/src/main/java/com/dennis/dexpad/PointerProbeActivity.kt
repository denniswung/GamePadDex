package com.dennis.dexpad

import android.app.Activity
import android.os.Bundle
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.TextView

/**
 * Debug-only probe used by the automated test scripts: a full-screen view that
 * logs every generic-motion (mouse) event it receives, in display pixels.
 * It is not shown in the launcher; tests start it with
 *   adb shell am start -n com.dennis.dexpad/.PointerProbeActivity
 */
class PointerProbeActivity : Activity() {

    private lateinit var label: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val root = object : ViewGroup(this) {
            override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
                label.layout(40, 40, r - 40, 300)
            }

            override fun onGenericMotionEvent(event: MotionEvent): Boolean {
                report(event)
                return true
            }

            override fun onHoverEvent(event: MotionEvent): Boolean {
                report(event)
                return true
            }
        }
        label = TextView(this).apply {
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            text = "pointer probe ready"
        }
        root.addView(label)
        root.setBackgroundColor(0xFF101010.toInt())
        setContentView(root)
    }

    private fun report(event: MotionEvent) {
        val line = "x=${event.x} y=${event.y} raw=${event.rawX},${event.rawY} action=${event.actionMasked}"
        Log.i("DexPadProbe", line)
        label.text = line
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                    View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
    }
}
