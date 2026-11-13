package com.dennis.gamepadmouse

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PointF
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Display
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import java.io.File

/**
 * Everything that turns "cursor position" into something the system sees.
 *
 * Two renderers exist:
 *  - [GestureRenderer] : draws our own cursor and injects touches with
 *    dispatchGesture (this is what the original app does, works without root).
 *  - native pointer      : the root helper owns a uinput mouse, the system draws
 *    its own pointer (best feeling on DeX, needs root).
 */
class PointerEngine(
    private val service: AccessibilityService,
    private val rootProvider: () -> RootInput?,
    private val haptics: (Long) -> Unit,
) {
    /** root scroll injector (ACTION_SCROLL); when present it is preferred */
    var injectorProvider: (() -> ScrollInjector?)? = null
    /** resolves the display every injection must target (DeX drifts) */
    var displayIdProvider: (() -> Int)? = null
    private var injectorMissingLogged = false
    private val root: RootInput? get() = try { rootProvider() } catch (_: Throwable) { null }
    private val handler = Handler(Looper.getMainLooper())

    var display: Display? = null
        private set
    private var displayWidth = 1080
    /** read-only view of the display width for the service */
    val width: Int get() = displayWidth
    val height2: Int get() = displayHeight
    private var displayHeight = 2400

    /** cursor position in display pixels */
    val pos = PointF(540f, 1200f)

    /** unit velocity from the left stick (already dead-zoned / curved) */
    var velocityX = 0f
        private set
    var velocityY = 0f
        private set

    /** unit direction of the right stick (scroll) */
    var scrollDirX = 0f
        private set
    var scrollDirY = 0f
        private set
    /** 0..1 deflection of the right stick (after the dead zone) */
    var scrollMag = 0f
        private set

    var enabled = false
        private set
    var nativePointer = false
        private set

    private var cursorView: ImageView? = null
    private var cursorParams: WindowManager.LayoutParams? = null
    private var cursorWindowManager: WindowManager? = null
    private var cursorSize = 100
    private var cursorAlphaTarget = 1f
    private var lastActivity = 0L
    private var timeoutSeconds = 0

    private var pressing = false
    private var pressStart = 0L
    private var dragging = false
    private var scrollBusy = false
    private var lastDragAt = 0L
    private var lastRepeatAt = 0L
    private var lastWheelAt = 0L
    private var lastScrollAt = 0L
    /** fractional wheel steps, so slow stick movement still scrolls */
    private var wheelAcc = 0f
    private var lastHScrollAt = 0L
    private var hScrollDir = 0
    private var hScrollLogged = false
    private var scrollAnchorX = 0f
    private var scrollAnchorY = 0f
    private var scrollX = 0f
    private var scrollY = 0f

    private val gesture = GestureRenderer(service)

    // ------------------------------------------------------------------ setup
    fun attachDisplay(display: Display) {
        this.display = display
        val metrics = android.util.DisplayMetrics()
        @Suppress("DEPRECATION")
        display.getRealMetrics(metrics)
        displayWidth = metrics.widthPixels
        displayHeight = metrics.heightPixels
        if (displayWidth <= 0 || displayHeight <= 0) {
            // some DeX displays report a zero-size DisplayInfo until they get
            // their first frame; fall back to the mode or a sane default
            displayWidth = display.mode.physicalWidth.takeIf { it > 0 } ?: 1920
            displayHeight = display.mode.physicalHeight.takeIf { it > 0 } ?: 1080
        }
        displayWidth = displayWidth.coerceAtLeast(320)
        displayHeight = displayHeight.coerceAtLeast(240)
        // EVERY injected gesture must target this display, otherwise it lands on
        // the (possibly off) default display
        gesture.setDisplayId(display.displayId)
        pos.x = displayWidth / 2f
        pos.y = displayHeight / 2f
        Log.i(TAG, "display ${display.displayId} ${displayWidth}x$displayHeight")
    }

    fun updateScreenSize(w: Int, h: Int) {
        displayWidth = w
        displayHeight = h
        pos.x = pos.x.coerceIn(0f, w.toFloat())
        pos.y = pos.y.coerceIn(0f, h.toFloat())
    }

    fun setNativePointer(enabled: Boolean) {
        nativePointer = enabled
    }

    fun setCursorSize(px: Int) {
        cursorSize = px
    }

    fun setTimeoutSeconds(s: Int) {
        timeoutSeconds = s
    }

    // ------------------------------------------------------------- lifecycle
    fun start(prefColor: Int, customImage: File?, sizePx: Int) {
        enabled = true
        cursorSize = sizePx
        lastActivity = SystemClock.elapsedRealtime()
        if (nativePointer) {
            removeCursor()
            // no forced reposition: the system pointer stays where the user left
            // it, our tracked position starts at the centre of the active display
            pos.set(displayWidth / 2f, displayHeight / 2f)
        } else {
            showCursor(prefColor, customImage)
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
    }

    fun stop() {
        enabled = false
        handler.removeCallbacks(tick)
        dragging = false
        pressing = false
        velocityX = 0f
        velocityY = 0f
        scrollDirX = 0f
        scrollDirY = 0f
        scrollDragActive = false
        scrollMag = 0f
        removeCursor()
    }

    fun destroy() {
        stop()
    }

    // -------------------------------------------------------------- movement
    fun setVelocity(x: Float, y: Float) {
        velocityX = x
        velocityY = y
    }

    /** independent horizontal channel (dir = -1/0/+1) */
    fun setHScroll(dir: Int) {
        hScrollDir = dir
        if (dir == 0) hScrollLogged = false
    }

    fun setScroll(x: Float, y: Float, magnitude: Float = 1f) {
        scrollDirX = x
        scrollDirY = y
        scrollMag = magnitude.coerceIn(0f, 1f)
    }

    fun touchActivity() {
        lastActivity = SystemClock.elapsedRealtime()
    }

    private fun dispatchHScroll(now: Long) {
        if (hScrollDir == 0) return
        if (now - lastHScrollAt < 90) return
        lastHScrollAt = now
        if (!hScrollLogged) {
            hScrollLogged = true
            Log.i(TAG, "HSCROLL dir=$hScrollDir display=${display?.displayId} at ${pos.x},${pos.y}")
        }
        val sweep = (40f + 160f * scrollMag) * (scrollSpeed / 2f)
        touchActivity()
        gesture.scroll(pos.x, pos.y, hScrollDir.toFloat(), 0f, sweep)
    }


    // ------------------------------------------------ continuous scroll drag
    private var scrollDragActive = false
    private var scrollAccX = 0f
    private var scrollAccY = 0f
    private var lastDragStepAt = 0L

    /**
     * One long touch drag that keeps being extended while the stick is held.
     * Driving it from the frame timer (instead of waiting for gesture callbacks,
     * which are unreliable on this device) removes the "many tiny flings" jitter
     * of the discrete swipe approach.
     */
    private fun continuousScroll(now: Long, sx: Float, sy: Float) {
        val active = sx != 0f || sy != 0f
        if (!active) {
            if (scrollDragActive) {
                gesture.endScrollDrag(displayWidth / 2f + scrollAccX, displayHeight / 2f + scrollAccY)
                scrollDragActive = false
            }
            return
        }
        val cx = displayWidth / 2f
        val cy = displayHeight / 2f
        if (!scrollDragActive) {
            scrollAccX = 0f
            scrollAccY = 0f
            scrollDragActive = true
            lastDragStepAt = now
            touchActivity()
            gesture.startScrollDrag(cx, cy)
            return
        }
        if (now - lastDragStepAt < 40) return
        lastDragStepAt = now
        val stepPx = (5f + 22f * scrollMag) * (scrollSpeed / 2f)
        scrollAccX += -sx * stepPx
        scrollAccY += sy * stepPx
        // keep the drag inside the display
        scrollAccX = scrollAccX.coerceIn(-cx * 0.8f, cx * 0.8f)
        scrollAccY = scrollAccY.coerceIn(-cy * 0.8f, cy * 0.8f)
        touchActivity()
        gesture.continueScrollDrag(cx + scrollAccX, cy + scrollAccY)
    }

    private val tick = object : Runnable {
        override fun run() {
            if (!enabled) return
            try {
                step()
            } catch (t: Throwable) {
                Log.e(TAG, "tick failed", t)
            } finally {
                handler.postDelayed(this, 16L)
            }
        }
    }

    private fun step() {
        val now = SystemClock.elapsedRealtime()
        if (velocityX != 0f || velocityY != 0f) {
            val speed = (if (speedProvider != null) speedProvider!!() else 50).toFloat()
            pos.x = (pos.x + velocityX * speed).coerceIn(0f, displayWidth.toFloat())
            pos.y = (pos.y + velocityY * speed).coerceIn(0f, displayHeight.toFloat())
            if (nativePointer) {
                val p = root
                if (p != null) {
                    p.move(velocityX * speed, velocityY * speed)
                }
            }
            moveCursorWindow()
            touchActivity()
            if (!nativePointer) {
                if (dragging) {
                    if (now - lastDragAt >= 40) {
                        lastDragAt = now
                        gesture.continueDrag(pos.x, pos.y)
                    }
                } else if (pressing && now - pressStart > 250) {
                    // held and moved -> promote to drag
                    dragging = true
                    gesture.startDrag(pos.x, pos.y)
                }
            }
        } else if (!nativePointer && dragging) {
            if (now - lastDragAt >= 40) {
                lastDragAt = now
                gesture.continueDrag(pos.x, pos.y)
            }
        } else if (!nativePointer && pressing && !dragging && now - pressStart > 500) {
            Log.i(TAG, "stationary long-press -> drag")
            dragging = true
            gesture.startDrag(pos.x, pos.y)
            haptics(40L)
        }

        // scroll while the right stick is deflected
        val sx = scrollDirX
        val sy = scrollDirY
        // continuousScroll(now, sx, sy)   // disabled: strokes were not delivered
        // touch-swipe scrolling, exactly like the original app: the stroke is
        // anchored at (cursorX, screenHeight/2) so it always crosses content
        run {
        dispatchHScroll(now)

        // discrete but small & frequent swipes (the variant that was verified to
        // work on this device); distance follows the stick deflection
        if ((sx != 0f || sy != 0f) && now - lastScrollAt >= 95) {
            lastScrollAt = now
            touchActivity()
            val ax = pos.x.coerceIn(0f, displayWidth.toFloat())
            val ay = pos.y.coerceIn(0f, displayHeight.toFloat())
            val dispId = (try { displayIdProvider?.invoke() } catch (t: Throwable) { null }) ?: display?.displayId ?: 0
            val lines = ((1f + 5f * scrollMag) * (scrollSpeed / 2f)) * 0.6f
            val horizontal = Math.abs(sx) > 0.01f && Math.abs(sy) < 0.01f
            var ok = false
            if (horizontal) {
                // Android apps almost never handle AXIS_HSCROLL, so horizontal
                // scrolling goes through a real touch swipe instead; use the same
                // small & frequent steps as the vertical path for a smooth feel
                if (now - lastHScrollAt >= 95) {
                    lastHScrollAt = now
                    val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                    touchActivity()
                    gesture.scroll(displayWidth / 2f, displayHeight / 2f, sx, 0f, sweep)
                }
                ok = true
            } else {
                // vertical: the SAME channel the left stick uses for the pointer -
                // uinput REL_WHEEL through the root helper. Kernel level events are
                // continuous, so scrolling is as smooth as cursor movement.
                val r = root
                if (r != null && r.isRunning) {
                    wheelAcc += (-sy) * (0.10f + 1.10f * scrollMag) * (scrollSpeed / 2f)
                    val steps = wheelAcc.toInt()
                    if (steps != 0) {
                        wheelAcc -= steps
                        touchActivity()
                        // the virtual mouse declares REL_WHEEL_HI_RES: 1 notch = 120
                        android.util.Log.i("GpmPointer", "wheel " + (steps * 120) + " sy=$sy")
                        r.wheel(steps * 120)
                    }
                    ok = true
                } else {
                    val sweep = (25f + 95f * scrollMag) * (scrollSpeed / 2f)
                    touchActivity()
                    gesture.scroll(displayWidth / 2f, displayHeight / 2f, -sx, sy, sweep)
                    ok = true
                }
            }
        }
        }

        // auto hide / auto disable
        if (!nativePointer) {
            val idle = now - lastActivity
            val maxIdle = if (timeoutSeconds > 0) timeoutSeconds * 1000L else 4000L
            if (idle > maxIdle && cursorAlphaTarget != 0f) fadeCursor(0f)
            else if (idle <= maxIdle && cursorAlphaTarget != 1f) fadeCursor(1f)
        }
    }

    var speedProvider: (() -> Int)? = null
    private fun scrollSweep(): Float {
        val base = if (display != null && display!!.displayId != 0) 1.2f else 1.0f
        return scrollSpeed * 180f * base
    }

    var scrollSpeed = 2.0f

    // ---------------------------------------------------------------- clicks
    fun onPrimaryDown() {
        Log.i(TAG, "primary down")
        touchActivity()
        pressStart = SystemClock.elapsedRealtime()
        pressing = true
        if (nativePointer) root?.button(0, true)
    }

    fun onPrimaryUp() {
        touchActivity()
        val now = SystemClock.elapsedRealtime()
        pressing = false
        if (nativePointer) {
            root?.button(0, false)
            return
        }
        if (dragging) {
            dragging = false
            gesture.endDrag(pos.x, pos.y)
        } else if (now - pressStart < 250) {
            Log.i(TAG, "tap at ${pos.x},${pos.y} disp=${display?.displayId}")
            gesture.tap(pos.x, pos.y)
        } else {
            // medium press: still a tap (the original only drags when moving)
            gesture.tap(pos.x, pos.y)
        }
    }

    fun secondaryClick() {
        Log.i(TAG, "double tap at ${pos.x},${pos.y} disp=${display?.displayId}")
        touchActivity()
        if (nativePointer) {
            root?.button(1, true)
            root?.button(1, false)
        } else {
            gesture.doubleTap(pos.x, pos.y)
        }
    }

    fun wheel(steps: Int) {
        if (nativePointer) root?.wheel(steps)
    }

    fun clickAt(x: Float, y: Float) {
        gesture.tap(x, y)
    }

    fun resetRepeatClock() {
        lastRepeatAt = SystemClock.elapsedRealtime()
    }

    // ---------------------------------------------------------------- cursor
    private fun showCursor(color: Int, customImage: File?) {
        val display = display ?: return
        removeCursor()
        val ctx: Context = try {
            service.createDisplayContext(display)
        } catch (t: Throwable) {
            service
        }
        var wm = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm = ctx.createWindowContext(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, null)
                .getSystemService(Context.WINDOW_SERVICE) as WindowManager
        } catch (_: Throwable) {
        }
        val px = displaySizePx()
        val view = ImageView(ctx)
        view.setImageDrawable(buildCursorDrawable(ctx, color, customImage, px))
        view.scaleType = ImageView.ScaleType.CENTER_INSIDE
        val lp = WindowManager.LayoutParams(
            px, px,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT,
        )
        lp.gravity = Gravity.START or Gravity.TOP
        lp.x = (pos.x - px / 2f).toInt()
        lp.y = (pos.y - px / 2f).toInt()
        try {
            wm.addView(view, lp)
            view.alpha = 0f
            cursorWindowManager = wm
            cursorView = view
            cursorParams = lp
            fadeCursor(1f)
        } catch (t: Throwable) {
            Log.e(TAG, "add cursor failed", t)
        }
    }

    private fun displaySizePx(): Int {
        val external = display != null && display!!.displayId != 0
        val size = if (external) (cursorSize * 0.4f).toInt() else cursorSize
        return size.coerceAtLeast(16)
    }

    /** used by the debug/test hook only */
    fun moveTo(x: Float, y: Float) {
        pos.x = x.coerceIn(0f, displayWidth.toFloat())
        pos.y = y.coerceIn(0f, displayHeight.toFloat())
        moveCursorWindow()
        Log.i(TAG, "moveTo ${pos.x},${pos.y}")
    }

    private fun buildCursorDrawable(ctx: Context, color: Int, customImage: File?, px: Int): Drawable {
        if (customImage != null && customImage.exists()) {
            val bmp = android.graphics.BitmapFactory.decodeFile(customImage.absolutePath)
            if (bmp != null) {
                val scaled = Bitmap.createScaledBitmap(bmp, px, px, true)
                return BitmapDrawable(ctx.resources, scaled)
            }
        }
        return BitmapDrawable(ctx.resources, arrowBitmap(px, color))
    }

    /** draws the "orange" arrow cursor, 0° pointing to the upper-left */
    private fun arrowBitmap(size: Int, color: Int): Bitmap {
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.FILL
        }
        val outline = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = size * 0.055f
        }
        val path = Path()
        val s = size.toFloat()
        path.moveTo(s * 0.16f, s * 0.06f)
        path.lineTo(s * 0.16f, s * 0.72f)
        path.lineTo(s * 0.36f, s * 0.55f)
        path.lineTo(s * 0.47f, s * 0.86f)
        path.lineTo(s * 0.60f, s * 0.80f)
        path.lineTo(s * 0.49f, s * 0.50f)
        path.lineTo(s * 0.74f, s * 0.48f)
        path.close()
        c.drawPath(path, fill)
        c.drawPath(path, outline)
        return bmp
    }

    private fun moveCursorWindow() {
        val view = cursorView ?: return
        val lp = cursorParams ?: return
        val px = displaySizePx()
        lp.x = (pos.x - px / 2f).toInt()
        lp.y = (pos.y - px / 2f).toInt()
        try {
            cursorWindowManager?.updateViewLayout(view, lp)
        } catch (_: Throwable) {
        }
    }

    private fun fadeCursor(target: Float) {
        cursorAlphaTarget = target
        val v = cursorView ?: return
        v.animate().alpha(target).setDuration(200L).start()
    }

    private fun removeCursor() {
        val v = cursorView ?: return
        cursorView = null
        try {
            val ctx = v.context
            val wm = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeView(v)
        } catch (_: Throwable) {
        } finally {
            cursorParams = null
            cursorWindowManager = null
        }
    }

    companion object {
        private const val TAG = "GpmPointer"
    }
}

/**
 * Thin wrapper around dispatchGesture that keeps at most one gesture in flight,
 * which is required for `continueStroke` to work reliably.
 */
class GestureRenderer(private val service: AccessibilityService) {
    private var inFlight = false
    private var displayId = Display.DEFAULT_DISPLAY

    fun setDisplayId(id: Int) {
        displayId = id
    }

    private fun builder(): GestureDescription.Builder {
        val b = GestureDescription.Builder()
        if (Build.VERSION.SDK_INT >= 30) b.setDisplayId(displayId)
        return b
    }

    fun tap(x: Float, y: Float) {
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0L, 50L)
        dispatch(builder().addStroke(stroke).build())
    }

    fun doubleTap(x: Float, y: Float) {
        val p1 = Path().apply { moveTo(x, y) }
        val p2 = Path().apply { moveTo(x, y) }
        val b = builder()
        b.addStroke(GestureDescription.StrokeDescription(p1, 0L, 50L))
        b.addStroke(GestureDescription.StrokeDescription(p2, 150L, 50L))
        dispatch(b.build())
        // and a right-click hint for apps that support it
    }

    fun scroll(x: Float, y: Float, dx: Float, dy: Float, sweep: Float, done: (() -> Unit)? = null) {
        Log.i("GpmGesture", "scroll on display $displayId at $x,$y dir=$dx,$dy sweep=$sweep")
        val path = Path()
        path.moveTo(x, y)
        path.lineTo(x - dx * sweep, y - dy * sweep)
        val stroke = GestureDescription.StrokeDescription(path, 0L, 95L)
        dispatch(builder().addStroke(stroke).build(), done)
    }

    // ---- continuous scroll drag ----
    private var scrollStroke: GestureDescription.StrokeDescription? = null
    private var scrollInFlight = false
    val scrollBusy: Boolean get() = scrollInFlight

    private val uiHandler = android.os.Handler(android.os.Looper.getMainLooper())

    /** the gesture callback is not reliable on every OEM build: always unblock by time */
    private fun markInFlight() {
        scrollInFlight = true
        uiHandler.postDelayed({ scrollInFlight = false }, 90L)
    }

    fun startScrollDrag(x: Float, y: Float) {
        try {
            val path = Path().apply { moveTo(x, y) }
            val s = GestureDescription.StrokeDescription(path, 0L, 60L, true)
            scrollStroke = s
            markInFlight()
            dispatch(builder().addStroke(s).build()) { scrollInFlight = false }
        } catch (t: Throwable) {
            Log.w("GpmGesture", "startScrollDrag: ${t.message}")
            scrollStroke = null
            scrollInFlight = false
        }
    }

    fun continueScrollDrag(x: Float, y: Float) {
        if (scrollInFlight) return
        val s = scrollStroke ?: run { startScrollDrag(x, y); return }
        try {
            val path = Path().apply { moveTo(x, y) }
            val next = s.continueStroke(path, 0L, 60L, true)
            scrollStroke = next
            markInFlight()
            dispatch(builder().addStroke(next).build()) { scrollInFlight = false }
        } catch (t: Throwable) {
            Log.w("GpmGesture", "continueScrollDrag: ${t.message}")
            scrollStroke = null
            scrollInFlight = false
            startScrollDrag(x, y)
        }
    }

    fun endScrollDrag(x: Float, y: Float) {
        val s = scrollStroke ?: return
        scrollStroke = null
        if (scrollInFlight) return
        try {
            val path = Path().apply { moveTo(x, y) }
            val next = s.continueStroke(path, 0L, 40L, false)
            scrollInFlight = true
            uiHandler.postDelayed({ scrollInFlight = false }, 90L)
            dispatch(builder().addStroke(next).build()) { scrollInFlight = false }
        } catch (t: Throwable) {
            Log.w("GpmGesture", "endScrollDrag: ${t.message}")
            scrollInFlight = false
        }
    }

    private var dragStroke: GestureDescription.StrokeDescription? = null

    fun startDrag(x: Float, y: Float) {
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0L, 50L, true)
        dragStroke = stroke
        dispatch(builder().addStroke(stroke).build())
    }

    fun continueDrag(x: Float, y: Float) {
        val stroke = dragStroke ?: return
        val path = Path().apply { moveTo(x, y) }
        val next = stroke.continueStroke(path, 0L, 50L, true)
        dragStroke = next
        dispatch(builder().addStroke(next).build())
    }

    fun endDrag(x: Float, y: Float) {
        val stroke = dragStroke ?: return
        dragStroke = null
        val path = Path().apply { moveTo(x, y) }
        val next = stroke.continueStroke(path, 0L, 50L, false)
        dispatch(builder().addStroke(next).build())
    }

    private fun dispatch(desc: GestureDescription, done: (() -> Unit)? = null) {
        try {
            service.dispatchGesture(desc, object : AccessibilityService.GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    done?.invoke()
                }

                override fun onCancelled(gestureDescription: GestureDescription?) {
                    done?.invoke()
                }
            }, null)
        } catch (t: Throwable) {
            Log.w("GpmGesture", "dispatch failed: ${t.message}")
            done?.invoke()
        }
    }
}
