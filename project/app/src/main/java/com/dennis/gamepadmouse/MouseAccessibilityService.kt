package com.dennis.gamepadmouse

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.hardware.display.DisplayManager
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.Display
import android.view.Gravity
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import java.io.File

/**
 * The accessibility service.
 *
 * Input comes from one of two places:
 *  - ROOT: [RootInput] grabbed the controller with EVIOCGRAB, so the framework
 *    (and therefore Samsung DeX's desktop navigation, GameTools, games) never
 *    sees it.  We read the raw events ourselves.
 *  - FALLBACK: a focusable accessibility overlay window receives the gamepad
 *    MotionEvents and onKeyEvent() receives the buttons (works without root).
 */
class MouseAccessibilityService : AccessibilityService(),
    RootInput.Listener {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences
    private var engine: PointerEngine? = null
    private var root: RootInput? = null
    private var useRoot = false
    private var rootWanted = false

    private val displayManager by lazy { getSystemService(Context.DISPLAY_SERVICE) as DisplayManager }

    /** one focus catcher window per active display */
    private val focusViews = HashMap<Int, Pair<View, WindowManager>>()
    private var display: Display? = null

    // --- input state -----------------------------------------------------
    private var hatX = 0f
    private var hatY = 0f
    /** KEYCODE_BUTTON_X is the modifier for the X+button mapping combos */
    private var modifierHeld = false
    private var hScrollDir = 0
    /** 0 = unlocked, 1 = horizontal locked, -1 = vertical locked */
    private var scrollAxisLock = 0

    /** key codes currently held, used for the full-key and combo mappings */
    private val pressedButtons = HashSet<Int>()
    /** package/activity currently in front on the DeX display */
    private var lastFgComponent: String? = null
    private val firedCombos = HashSet<Int>()
    private var leftX = 0f
    private var leftY = 0f
    private var ltDown = false
    private var rtDown = false
    private val comboHeld = HashMap<String, Boolean>()

    // --- toggle (L3 / long-press) ---------------------------------------
    private var toggleDownAt = 0L
    private var toggleLongFired = false
    private var pendingToggle = false

    private val longPressRunnable = Runnable {
        if (pendingToggle && mouseMode) {
            // long press in mouse mode = turn it off (only when a long-press
            // duration is configured)
            android.util.Log.i(TAG, "toggle long-press fired")
            toggleMouseMode(false)
        }
        toggleLongFired = true
    }

    val mouseMode: Boolean get() = engine?.enabled == true

    val pointerEngine: PointerEngine? get() = engine

    private var repeatRunnable: Runnable? = null
    private var repeatX = 0f
    private var repeatY = 0f

    /** repeat-click at a captured location (action click_location_repeat) */
    fun startRepeatClick(x: Float, y: Float, intervalMs: Int) {
        stopRepeatClick()
        repeatX = x
        repeatY = y
        val period = intervalMs.coerceIn(100, 5000).toLong()
        val r = object : Runnable {
            override fun run() {
                engine?.clickAt(repeatX, repeatY)
                handler.postDelayed(this, period)
            }
        }
        repeatRunnable = r
        handler.postDelayed(r, period)
    }

    fun stopRepeatClick() {
        repeatRunnable?.let { handler.removeCallbacks(it) }
        repeatRunnable = null
    }

    /** cursor position, used by the "click location" capture flow */
    fun cursorPosition(): android.graphics.PointF? = engine?.pos

    // ------------------------------------------------------------------ init
    override fun onServiceConnected() {
        gpmService = this
        Log.i(TAG, "onServiceConnected")
        prefs = Prefs.get(this)
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100L
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS or
                AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        }
        serviceInfo = info

        val e = PointerEngine(this, { root }) { ms -> haptic(ms) }
        e.injectorProvider = { injector }
        e.displayIdProvider = { targetDisplayId() }
        engine = e
        e.scrollSpeed = Prefs.scrollSpeed(prefs)
        e.speedProvider = { if (currentDisplayIsPhone()) Prefs.mouseSpeed(prefs) else Prefs.dexSpeed(prefs) }
        e.setCursorSize(Prefs.mouseSize(prefs))
        e.setTimeoutSeconds(Prefs.timeoutSeconds(prefs))

        registerToggleReceiver()
        prefs.registerOnSharedPreferenceChangeListener(prefListener)
        displayManager.registerDisplayListener(displayListener, handler)

        pickDisplay()
        if (Prefs.startMouseMode(prefs)) {
            // default: the pad drives our pointer; a mapped button hands it back.
            // retry for up to ~12s until the root helper is actually connected,
            // otherwise the first switch happens before the engine has a display.
            var tries = 0
            val arm = object : Runnable {
                override fun run() {
                    tries++
                    if (mouseMode) return
                    val ready = root?.helperReady == true || tries > 8
                    if (ready) {
                        toggleMouseMode(true)
                        Log.i(TAG, "auto-entered mouse mode on service start (try " + tries + ")")
                    } else {
                        handler.postDelayed(this, 1500L)
                    }
                }
            }
            handler.postDelayed(arm, 1500L)
        }
        if (Prefs.alwaysGrab(prefs) && prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {
            // block the stock gamepad handler even in normal (non mouse) mode
            handler.postDelayed({ root?.grab() }, 800L)
            Log.i(TAG, "always-grab enabled: stock gamepad input is blocked")
        }

        // root first (async: `su` may need a one-time approval), fallback second
        if (prefs.getBoolean(Prefs.ROOT_ENABLED, true)) {
            rootWanted = true
            startRoot()
            handler.postDelayed(rootRetry, 6000L)
        }
        Log.i(TAG, "ready, root=${useRoot}")
    }

    /** keeps trying to get the root helper (socket may appear later, su may be approved late) */
    private val rootRetry = object : Runnable {
        override fun run() {
            if (!prefs.getBoolean(Prefs.ROOT_ENABLED, true)) return
            if (root?.helperReady != true) {
                root?.stop()
                root = null
                startRoot()
            }
            // the native/gesture backend depends on the helper: if it came or
            // went away while mouse mode is on, rebuild the pointer
            val native = root?.helperReady == true &&
                prefs.getBoolean(Prefs.NATIVE_POINTER, true)
            if (mouseMode && native != lastNativeMode) {
                lastNativeMode = native
                toggleMouseMode(false)
                toggleMouseMode(true)
            }
            handler.postDelayed(this, if (root?.helperReady == true) 10000L else 6000L)
        }
    }

    private var lastNativeMode = false
    private val injector by lazy { ScrollInjector("gpm_scroll") }

    private val toggleReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_SNAP -> snapToFiles()
                ACTION_DEBUG -> {
                    // test hook: move the pointer outright / double click
                    val e = engine ?: return
                    val mx = intent.getFloatExtra("mx", -1f)
                    val my = intent.getFloatExtra("my", -1f)
                    if (mx >= 0f && my >= 0f) e.moveTo(mx, my)
                    if (intent.getBooleanExtra("double", false)) e.secondaryClick()
                    when (intent.getStringExtra("mode")) {
                        "on" -> toggleMouseMode(true)
                        "off" -> toggleMouseMode(false)
                    }
                    if (intent.getBooleanExtra("click", false)) { e.onPrimaryDown(); e.onPrimaryUp() }
                }
                else -> toggleMouseMode(!mouseMode)
            }
        }
    }

    private fun registerToggleReceiver() {
        try {
            registerReceiver(
                toggleReceiver,
                android.content.IntentFilter().apply {
                    addAction(ACTION_TOGGLE)
                    addAction(ACTION_SNAP)
                    addAction(ACTION_DEBUG)
                },
                RECEIVER_NOT_EXPORTED,
            )
        } catch (t: Throwable) {
            Log.w(TAG, "toggle receiver: ${t.message}")
        }
    }

    private fun startRoot() {
        if (root != null) return
        val sock = prefs.getString(Prefs.HELPER_SOCKET, "").let { if (it.isNullOrBlank()) File(filesDir, "gpm.sock").absolutePath else it }
        val r = RootInput(this, this, sock)
        root = r
        r.start()
    }

    /**
     * Debug helper: capture the active display through the accessibility
     * screenshot API (the only API that can grab a DeX display) and drop it in
     * filesDir so it can be pulled with adb.
     */
    fun snapToFiles(): String {
        if (android.os.Build.VERSION.SDK_INT < 30) return ""
        val id = display?.displayId ?: Display.DEFAULT_DISPLAY
        val out = File(filesDir, "snap_${System.currentTimeMillis()}.png")
        try {
            takeScreenshot(id, mainExecutor, object : AccessibilityService.TakeScreenshotCallback {
                override fun onSuccess(result: AccessibilityService.ScreenshotResult) {
                    try {
                        val bmp = android.graphics.Bitmap.wrapHardwareBuffer(
                            result.hardwareBuffer, result.colorSpace
                        )?.let { android.graphics.Bitmap.createBitmap(it) }
                        java.io.FileOutputStream(out).use { fos ->
                            bmp?.compress(android.graphics.Bitmap.CompressFormat.PNG, 92, fos)
                        }
                        Log.i(TAG, "SNAP ${out.absolutePath} ${bmp?.width}x${bmp?.height}")
                        result.hardwareBuffer.close()
                    } catch (t: Throwable) {
                        Log.w(TAG, "SNAP save failed: ${t.message}")
                    }
                }

                override fun onFailure(errorCode: Int) {
                    Log.w(TAG, "SNAP failed $errorCode")
                }
            })
        } catch (t: Throwable) {
            Log.w(TAG, "SNAP exception: ${t.message}")
        }
        return out.absolutePath
    }

    private fun stopRoot() {
        root?.stop()
        root = null
        useRoot = false
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        engine?.destroy()
        stopRoot()
        removeFocusViews()
        try {
            unregisterReceiver(toggleReceiver)
        } catch (_: Throwable) {
        }
        try {
            prefs.unregisterOnSharedPreferenceChangeListener(prefListener)
        } catch (_: Throwable) {
        }
        try {
            displayManager.unregisterDisplayListener(displayListener)
        } catch (_: Throwable) {
        }
        super.onDestroy()
    }

    override fun onInterrupt() {
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val pkg = event.packageName?.toString()
            val cls = event.className?.toString()
            val disp = try { event.displayId } catch (t: Throwable) { 0 }
            if (!pkg.isNullOrBlank() && !cls.isNullOrBlank() &&
                cls.startsWith(pkg) && disp != 0 && disp == targetDisplayId()
            ) {
                lastFgComponent = pkg + "/" + cls
            }
        }
        // DeX window model reports focus changes here, not via isFocused
        when (event?.eventType) {
            AccessibilityEvent.TYPE_WINDOWS_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handler.removeCallbacks(displayRefresh)
                handler.postDelayed(displayRefresh, 120L)
            }
        }
    }

    // ------------------------------------------------------- display handling
    private fun currentDisplayIsPhone(): Boolean = (display?.displayId ?: 0) == 0

    /** the display every injected event must target: the external/DeX one when present */
    fun targetDisplayId(): Int {
        return try {
            val dm = getSystemService(DisplayManager::class.java)
            val all = dm.displays
            val ext = all.firstOrNull { it.displayId != Display.DEFAULT_DISPLAY && it.state == Display.STATE_ON }
                ?: all.firstOrNull { it.displayId != Display.DEFAULT_DISPLAY }
            ext?.displayId ?: display?.displayId ?: Display.DEFAULT_DISPLAY
        } catch (t: Throwable) {
            display?.displayId ?: Display.DEFAULT_DISPLAY
        }
    }

    /** display id that currently owns the input focus (-1 = unknown) */
    private fun focusedDisplayId(): Int {
        return try {
            windows?.firstOrNull { it.isFocused }?.displayId ?: -1
        } catch (t: Throwable) {
            -1
        }
    }

    /** the one display we control: an external (DeX/HDMI) one if present, else the phone */
    private fun pickDisplay() {
        try {
            pickDisplayImpl()
        } catch (t: Throwable) {
            Log.e(TAG, "pickDisplay failed: " + t, t)
            // never lose the pointer: fall back to the default display
            val fallback = displayManager.getDisplay(Display.DEFAULT_DISPLAY) ?: return
            if (display?.displayId != fallback.displayId) {
                display = fallback
                try {
                    engine?.attachDisplay(fallback)
                } catch (t2: Throwable) {
                    Log.e(TAG, "attach fallback failed: " + t2, t2)
                }
            }
        }
    }

    private fun pickDisplayImpl() {
        val forceMirror = prefs.getBoolean(Prefs.FORCE_MIRRORING, false)
        val all = displayManager.displays
        // 只要有外接/DeX 屏就只用它：手机屏不参与控制
        var chosen: Display? = null
        val focusId = focusedDisplayId()
        if (focusId > 0) {
            chosen = all.firstOrNull { it.displayId == focusId }
        }
        if (chosen == null) {
            for (d in all) {
                if (d.displayId != Display.DEFAULT_DISPLAY) { chosen = d; break }
            }
        }
        if (chosen == null) chosen = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
        val target: Display = chosen ?: return
        Log.i(TAG, "pick: focus=" + focusId + " all=" + all.joinToString { "${it.displayId}/${it.state}" } + " -> target=" + target.displayId)
        val previous = display
        display = target
        val e = engine ?: return
        if (previous != null && previous.displayId == target.displayId) {
            e.updateScreenSize(target.realWidth(), target.realHeight())
            return
        }
        android.util.Log.i(TAG, "ATTACH display " + target.displayId)
        e.attachDisplay(target)
        if (e.enabled) {
            toggleMouseMode(false)
            toggleMouseMode(true)
        } else if (root?.helperReady != true) {
            updateFocusCatchers()
        }
    }

    /** DeX display callbacks are unreliable, poll as a safety net */
    private var pollCount = 0

    private val displayWatch = object : Runnable {
        override fun run() {
            try {
                pollCount++
                pickDisplay()
                if (pollCount % 10 == 0) {
                    Log.i(TAG, "poll#" + pollCount + " focus=" + focusedDisplayId() +
                        " target=" + (display?.displayId ?: -1))
                }
            } catch (t: Throwable) {
                Log.w(TAG, "displayWatch: ${t.message}")
            }
            handler.postDelayed(this, 300L)
        }
    }

    private fun Display.realWidth(): Int = android.util.DisplayMetrics().also {
        @Suppress("DEPRECATION")
        getRealMetrics(it)
    }.widthPixels

    private fun Display.realHeight(): Int = android.util.DisplayMetrics().also {
        @Suppress("DEPRECATION")
        getRealMetrics(it)
    }.heightPixels

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = scheduleDisplayRefresh()
        override fun onDisplayRemoved(displayId: Int) = scheduleDisplayRefresh()
        override fun onDisplayChanged(displayId: Int) = scheduleDisplayRefresh()

        private fun scheduleDisplayRefresh() {
            handler.removeCallbacks(displayRefresh)
            handler.postDelayed(displayRefresh, 100L)
        }
    }

    private val displayRefresh = Runnable {
        pickDisplay()
        // the focus catcher is only needed (and only harmless) while
        // mouse mode is on; otherwise it steals the DeX focus
        if (mouseMode && root?.helperReady != true) updateFocusCatchers()
    }

    // ------------------------------------------------------- mouse mode toggle
    private var inToggle = false

    fun toggleMouseMode(on: Boolean) {
        val e = engine ?: return
        if (inToggle || on == e.enabled) return
        inToggle = true
        try {
            if (on) {
                val color = cursorColor()
                val custom = File(filesDir, "custom_cursor.png").takeIf { it.exists() }
                e.attachDisplay(display ?: displayManager.getDisplay(Display.DEFAULT_DISPLAY))
                e.setCursorSize(Prefs.mouseSize(prefs))
                e.setTimeoutSeconds(Prefs.timeoutSeconds(prefs))
                e.scrollSpeed = Prefs.scrollSpeed(prefs)
                e.setNativePointer(prefs.getBoolean(Prefs.NATIVE_POINTER, true) && root?.helperReady == true)
                e.start(color, custom, Prefs.mouseSize(prefs))
                // grab the controller so Samsung / DeX never sees it
                if (root?.helperReady == true) {
                root?.grab()
                root?.queryCursor()   // sync our tracked position with the real pointer
            } else {
                updateFocusCatchers()
            }
                haptic(50L)
                Log.i(TAG, "mouse mode ON (root=${root?.helperReady == true})")
            } else {
                e.stop()
                stopRepeatClick()
                if (root?.helperReady == true) root?.ungrab() else removeFocusViews()
                haptic(50L)
                Log.i(TAG, "mouse mode OFF")
            }
            broadcastState()
        } finally {
            inToggle = false
        }
    }

    private fun cursorColor(): Int = try {
        Color.parseColor(prefs.getString(Prefs.CURSOR_COLOR, "#FFA000"))
    } catch (t: Throwable) {
        Color.parseColor("#FFA000")
    }

    private fun broadcastState() {
        val i = Intent(ACTION_STATE).setPackage(packageName)
        i.putExtra(EXTRA_MOUSE_ON, mouseMode)
        sendBroadcast(i)
    }

    // ------------------------------------------------------------ root input
    override fun onAxis(axis: Int, value: Float) = handleAxis(axis, value)

    override fun onKey(keyCode: Int, action: Int) {
        handleKey(keyCode, action, 0)
    }

    override fun onReady() {
        useRoot = true
        removeFocusViews()
        if (mouseMode) {
            // the helper just became available: switch to grab + native pointer
            root?.grab()
            lastNativeMode = prefs.getBoolean(Prefs.NATIVE_POINTER, true)
            toggleMouseMode(false)
            toggleMouseMode(true)
        } else {
            root?.ungrab()
        }
        Log.i(TAG, "root helper ready: controller is owned by us while mouse mode is on")
    }

    override fun onCursorPos(x: Float, y: Float) {
        engine?.moveTo(x, y)
        Log.i(TAG, "cursor synced to $x,$y")
    }

    override fun onDevicesChanged(names: List<String>) {
        useRoot = names.isNotEmpty() || (root?.isRunning == true)
        Log.i(TAG, "devices: $names (rootActive=${root?.isRunning})")
    }

    override fun onLog(line: String) {
        Log.i(TAG, "helper: $line")
    }

    // -------------------------------------------------------------- gamepad
    private fun handleAxis(axis: Int, value: Float) {
        val e = engine ?: return
        Log.i("GpmAxis", "axis=$axis value=$value enabled=${e.enabled}")
        // ---- independent horizontal scroll channel (right stick X) ----
        // The pad may report it as AXIS_Z (no RX/RY pair) or AXIS_RX.
        when (axis) {
            MotionEvent.AXIS_Z, MotionEvent.AXIS_RX, MotionEvent.AXIS_WHEEL, MotionEvent.AXIS_THROTTLE -> {
                val dir = if (Math.abs(value) > 0.35f) (if (value > 0f) -1 else 1) else 0
                if (dir != hScrollDir) {
                    hScrollDir = dir
                    Log.i(TAG, "hscroll raw axis=$axis value=$value -> dir=$dir")
                }
                e.setHScroll(dir)
            }
        }
        when (axis) {
            MotionEvent.AXIS_HAT_X -> {
                hatX = value
                onHat(hatX, hatY)
            }
            MotionEvent.AXIS_HAT_Y -> {
                hatY = value
                onHat(hatX, hatY)
            }
            MotionEvent.AXIS_X -> {
                leftX = value
                applyLeftStick()
            }
            MotionEvent.AXIS_Y -> {
                leftY = value
                applyLeftStick()
            }
            MotionEvent.AXIS_Z, MotionEvent.AXIS_RX, MotionEvent.AXIS_RZ, MotionEvent.AXIS_RY,
            MotionEvent.AXIS_THROTTLE, MotionEvent.AXIS_RUDDER, MotionEvent.AXIS_WHEEL -> {
                scrollAxes[axis] = value
                applyRightStick()
            }
            MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_BRAKE -> {
                val down = value > 0.5f
                if (down != ltDown) {
                    ltDown = down
                    onSlot("lt", down)
                }
            }
            MotionEvent.AXIS_RTRIGGER, MotionEvent.AXIS_GAS -> {
                val down = value > 0.5f
                if (down != rtDown) {
                    rtDown = down
                    onSlot("rt", down)
                }
            }
            else -> if (Build.VERSION.SDK_INT >= 33 && (axis == MotionEvent.AXIS_RX || axis == MotionEvent.AXIS_RY)) {
                // handled above
            }
        }
        if (e.enabled) e.touchActivity()
    }

    private val scrollAxes = HashMap<Int, Float>()

    private fun applyLeftStick() {
        val e = engine ?: return
        if (!e.enabled) return
        val dz = Prefs.deadzone(prefs)
        val hypot = Math.hypot(leftX.toDouble(), leftY.toDouble()).toFloat()
        if (hypot <= dz) {
            e.setVelocity(0f, 0f)
            return
        }
        // dead-zone rescaled magnitude 0..1
        val mag = (hypot - dz) / (1f - dz)
        // sensitivity curve (same shape as the original):
        //   a = (sens-1)/2            -> 0 .. 1
        //   out = mag^2.5 * a * 0.9 + (1 - a*0.9) * mag
        val sens = Prefs.sensitivity(prefs)
        val a = (sens - 1f) / 2f
        val out = (Math.pow(mag.toDouble(), 2.5) * a * 0.9f).toFloat() + (1f - a * 0.9f) * mag
        val ux = leftX / hypot
        val uy = leftY / hypot
        e.setVelocity(ux * out, uy * out)
    }

    private fun applyRightStick() {
        val e = engine ?: return
        if (!e.enabled) return
        val z = scrollAxes[MotionEvent.AXIS_Z] ?: 0f
        val rx = scrollAxes[MotionEvent.AXIS_RX] ?: 0f
        val rz = scrollAxes[MotionEvent.AXIS_RZ] ?: 0f
        val ry = scrollAxes[MotionEvent.AXIS_RY] ?: 0f
        val thr = scrollAxes[MotionEvent.AXIS_THROTTLE] ?: 0f
        val rud = scrollAxes[MotionEvent.AXIS_RUDDER] ?: 0f
        val whl = scrollAxes[MotionEvent.AXIS_WHEEL] ?: 0f
        val x = listOf(z, rx, thr, whl).maxByOrNull { Math.abs(it) } ?: 0f
        val y = listOf(rz, ry, rud).maxByOrNull { Math.abs(it) } ?: 0f
        val dz = Prefs.deadzone(prefs)
        val hypot = Math.hypot(x.toDouble(), y.toDouble()).toFloat()
        if (hypot <= dz) {
            e.setScroll(0f, 0f, 0f)
            return
        }
        // ---- axis lock with hysteresis (prevents accidental vertical trigger) ----
        //  * a lock is only taken when one axis clearly dominates (1.6x) AND the
        //    deflection is beyond the activation threshold
        //  * once locked, the other axis is forced to zero until the stick comes
        //    back near centre - so a horizontal swipe can never drift into a
        //    vertical scroll halfway through
        var ux = x / hypot
        var uy = y / hypot
        val ax = Math.abs(ux)
        val ay = Math.abs(uy)
        val lockThreshold = 0.35f          // minimum deflection to start scrolling
        val dominance = 1.6f               // how clearly one axis must win
        if (scrollAxisLock == 1) {
            if (ax < 0.25f || ay > ax * 0.9f) scrollAxisLock = 0
        } else if (scrollAxisLock == -1) {
            if (ay < 0.25f || ax > ay * 0.9f) scrollAxisLock = 0
        }
        if (scrollAxisLock == 0 && hypot >= lockThreshold) {
            when {
                ax > ay * dominance -> scrollAxisLock = 1
                ay > ax * dominance -> scrollAxisLock = -1
            }
        }
        when (scrollAxisLock) {
            1 -> {
                ux = if (x > 0f) 1f else -1f
                uy = 0f
            }
            -1 -> {
                uy = if (y > 0f) 1f else -1f
                ux = 0f
            }
            else -> {
                // no clear winner yet: fall back to the dominant axis so scrolling
                // never dies completely (the stick may be pushed off-centre)
                if (Math.abs(x) >= Math.abs(y)) {
                    ux = if (x > 0f) 1f else -1f
                    uy = 0f
                } else {
                    ux = 0f
                    uy = if (y > 0f) 1f else -1f
                }
            }
        }
        val mag = ((hypot - dz) / (1f - dz)).coerceIn(0f, 1f)
        e.setScroll(ux, uy, mag)
    }

    private fun onHat(x: Float, y: Float) {
        if (modifierHeld) {
            onSlot("left", x < -0.5f)
            onSlot("right", x > 0.5f)
            onSlot("up", y < -0.5f)
            onSlot("down", y > 0.5f)
            return
        }
        dpadKey(KeyEvent.KEYCODE_DPAD_LEFT, x < -0.5f)
        dpadKey(KeyEvent.KEYCODE_DPAD_RIGHT, x > 0.5f)
        dpadKey(KeyEvent.KEYCODE_DPAD_UP, y < -0.5f)
        dpadKey(KeyEvent.KEYCODE_DPAD_DOWN, y > 0.5f)
    }

    private val dpadState = HashMap<Int, Boolean>()

    /** reproduces the framework HAT->DPAD conversion, then the app's defaults */
    private fun dpadKey(code: Int, down: Boolean) {
        if (dpadState[code] == down) return
        dpadState[code] = down
        if (!down) return
        when (code) {
            KeyEvent.KEYCODE_DPAD_LEFT -> mediaKey(KeyEvent.KEYCODE_MEDIA_REWIND)
            KeyEvent.KEYCODE_DPAD_RIGHT -> mediaKey(KeyEvent.KEYCODE_MEDIA_FAST_FORWARD)
            else -> Unit
        }
        if (engine?.enabled == true) engine?.touchActivity()
    }

    private fun mediaKey(androidCode: Int) {
        try {
            val r = root
            if (r != null && r.isRunning) {
                // display targeted first: media keys must stay on the DeX screen
                val disp = targetDisplayId()
                if (r.helperReady && r.pointKey(disp, androidCode)) {
                    Log.i(TAG, "media key " + androidCode + " -> display " + disp)
                    return
                }
                val linux = KeyMap.toLinux(androidCode)
                if (linux != null) {
                    r.key(linux, true)
                    r.key(linux, false)
                    return
                }
            }
            val am = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, androidCode))
            am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, androidCode))
        } catch (t: Throwable) {
            Log.w(TAG, "mediaKey $androidCode failed: ${t.message}")
        }
    }

    /** R3: cycle the active display (phone <-> DeX) */
    private fun toggleDisplay() {
        val all = displayManager.displays.filter { it.state == Display.STATE_ON }
        if (all.size < 2) return
        val cur = display?.displayId ?: 0
        val idx = all.indexOfFirst { it.displayId == cur }
        val next = all[(idx + 1) % all.size]
        display = next
        engine?.attachDisplay(next)
        if (mouseMode) {
            toggleMouseMode(false)
            toggleMouseMode(true)
        }
        Log.i(TAG, "active display -> ${next.displayId}")
    }

    private fun onSlot(slot: String, down: Boolean) {
        if (comboHeld[slot] == down) return
        comboHeld[slot] = down
        if (down) {
            val action = prefs.getString(Prefs.mappingType(slot), "none") ?: "none"
            if (action != "none") {
                ActionDispatcher.run(this, prefs, action, prefs.getString(Prefs.mappingValue(slot), "") ?: "", slot)
                haptic(30L)
                if (engine?.enabled == true) engine?.touchActivity()
            }
        }
    }


    /**
     * global actions (home / recents / back) are performed on the display we
     * control, otherwise they land on the phone's screen while DeX is active
     */
    fun fireGlobalKey(keyCode: Int) {
        val disp = targetDisplayId()
        if (disp != 0 && root?.helperReady == true) {
            root?.pointKey(disp, keyCode)
            Log.i(TAG, "global key " + keyCode + " -> display " + disp)
            return
        }
        if (disp != 0 && keyCode == KeyEvent.KEYCODE_HOME && root?.helperReady == true) {
            root?.dexHome(disp)
            Log.i(TAG, "dex home on display " + disp)
            return
        }
        when (keyCode) {
            KeyEvent.KEYCODE_HOME -> performGlobalAction(GLOBAL_ACTION_HOME)
            KeyEvent.KEYCODE_APP_SWITCH -> performGlobalAction(GLOBAL_ACTION_RECENTS)
            KeyEvent.KEYCODE_BACK -> performGlobalAction(GLOBAL_ACTION_BACK)
            else -> performGlobalAction(GLOBAL_ACTION_HOME)
        }
    }


    // ---------------- DeX titlebar control (accessibility nodes) ----------------
    private fun collectClickable(n: AccessibilityNodeInfo?, out: MutableList<AccessibilityNodeInfo>, depth: Int) {
        if (n == null || depth > 12) return
        if (n.isClickable && n.isVisibleToUser) out.add(n)
        for (i in 0 until n.childCount) {
            collectClickable(n.getChild(i), out, depth + 1)
        }
    }

    /** clickable nodes in the DeX window titlebar strip, right to left */
    fun dexTitlebarCandidates(): List<AccessibilityNodeInfo> {
        val target = targetDisplayId()
        val result = ArrayList<AccessibilityNodeInfo>()
        val ws = try { windows } catch (t: Throwable) { null }
        Log.i(TAG, "probe: windows=" + (ws?.size ?: -1))
        val activeRoot = try { rootInActiveWindow } catch (t: Throwable) { null }
        Log.i(TAG, "probe: activeRoot=" + activeRoot?.packageName + " nodes=" + activeRoot?.childCount)
        if (ws == null || ws.isEmpty()) {
            // enumerate other apps' windows is not allowed here: fall back to the
            // focused window, whose decor view carries the DeX titlebar buttons
            if (activeRoot != null) {
                val all2 = ArrayList<AccessibilityNodeInfo>()
                collectClickable(activeRoot, all2, 0)
                val rect = android.graphics.Rect()
                for (n in all2) {
                    n.getBoundsInScreen(rect)
                    if (rect.top < 160 && rect.height() in 1..120) {
                        Log.i(TAG, "focused-win cand cls=${n.className} desc=${n.contentDescription} text=${n.text} bounds=$rect")
                        result.add(n)
                    }
                }
                result.sortByDescending { n ->
                    val r2 = android.graphics.Rect(); n.getBoundsInScreen(r2); r2.left
                }
            }
            return result
        }
        for (w in ws) {
            Log.i(TAG, "window dump: id=" + w.id + " type=" + w.type + " display=" + w.displayId +
                " active=" + w.isActive + " focused=" + w.isFocused + " title=" + w.title)
        }
        for (w in ws) {
            if (w.displayId != target) continue
            if (w.type != AccessibilityWindowInfo.TYPE_APPLICATION) continue
            val r = w.root ?: continue
            val all = ArrayList<AccessibilityNodeInfo>()
            collectClickable(r, all, 0)
            val rect = android.graphics.Rect()
            for (n in all) {
                n.getBoundsInScreen(rect)
                if (rect.top < 160 && rect.height() in 1..120 && rect.left > 0) {
                    Log.i(TAG, "titlebar cand cls=${n.className} desc=${n.contentDescription} text=${n.text} bounds=$rect")
                    result.add(n)
                }
            }
            break
        }
        result.sortByDescending { n ->
            val rect = android.graphics.Rect(); n.getBoundsInScreen(rect); rect.left
        }
        return result
    }

    /** click the fullscreen / maximize button in the DeX titlebar */
    fun dexFullscreenClick(): Boolean {
        val cands = dexTitlebarCandidates()
        if (cands.isEmpty()) {
            Log.w(TAG, "dex fullscreen: no titlebar nodes")
            return false
        }
        // prefer an explicit fullscreen / maximize description
        val byName = cands.firstOrNull { n ->
            val d = ((n.contentDescription?.toString() ?: "") + " " + (n.text?.toString() ?: "")).lowercase()
            d.contains("fullscreen") || d.contains("full screen") || d.contains("全屏") ||
                d.contains("maximize") || d.contains("最大化")
        }
        val pick = byName ?: cands.getOrNull(1) ?: cands.first()
        val rect = android.graphics.Rect(); pick.getBoundsInScreen(rect)
        Log.i(TAG, "dex fullscreen: clicking ${pick.className} desc=${pick.contentDescription} bounds=$rect total=${cands.size}")
        return pick.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    /** width of the display we control (for position maths in the helper) */
    val screenWidth: Int?
        get() = engine?.width
    val screenHeight: Int?
        get() = engine?.height2

    /** apply the "block stock gamepad input" preference right away */
    fun applyAlwaysGrab(checked: Boolean) {
        if (checked) root?.grab() else if (!mouseMode) root?.ungrab()
    }

    /** entry point for debug broadcasts / other components */
    fun runMappedAction(action: String, value: String) = fireAction(action, value)

    /** runs a mapped action, including the pseudo actions handled here */
    private fun fireAction(action: String, value: String) {
        Log.i(TAG, "fireAction " + action + " " + value)
        try {
            // visible feedback: lets the user see that a remap fired at all
            android.widget.Toast.makeText(this, "映射: " + action + (if (value.isBlank()) "" else " " + value),
                android.widget.Toast.LENGTH_SHORT).show()
        } catch (t: Throwable) {
        }
        when (action) {
            "mouse_click" -> engine?.let { it.onPrimaryDown(); it.onPrimaryUp() }
            "back" -> fireGlobalKey(KeyEvent.KEYCODE_BACK)
            "toggle_mouse" -> toggleMouseMode(!mouseMode)
            "scroll_up", "scroll_down" -> {
                val e = engine ?: return
                val dy = if (action == "scroll_up") 3f else -3f
                root?.pointScroll(e.pos.x, e.pos.y, dy, 0f, targetDisplayId())
            }
            "probe_windows" -> {
                val ws = try { windows } catch (t: Throwable) { null }
                Log.i(TAG, "PROBE windows=" + (ws?.size ?: -1))
                ws?.forEach { w ->
                    Log.i(TAG, "PROBE win type=" + w.type + " disp=" + w.displayId +
                        " active=" + w.isActive + " focused=" + w.isFocused + " title=" + w.title)
                }
                val activeRoot = try { rootInActiveWindow } catch (t: Throwable) { null }
                Log.i(TAG, "PROBE activeRoot=" + activeRoot?.packageName + " children=" + activeRoot?.childCount)
                val cands = dexTitlebarCandidates()
                Log.i(TAG, "PROBE titlebar candidates=" + cands.size)
            }
            "dex_fullscreen" -> {
                val dispNow = targetDisplayId()
                val rootOk = try { root?.fullscreenClick(dispNow, screenWidth ?: 0, screenHeight ?: 0) ?: false } catch (t: Throwable) { false }
                // a restarting helper can drop the first click: retry once shortly after
                handler.postDelayed({
                    runCatching { root?.fullscreenClick(dispNow, screenWidth ?: 0, screenHeight ?: 0) }
                }, 1200L)
                Log.i(TAG, "dex_fullscreen caption click -> " + rootOk + " display " + dispNow)
                val ok = rootOk || dexFullscreenClick()
                Log.i(TAG, "dex_fullscreen via titlebar -> " + ok)
                if (!ok) {
                    val disp = targetDisplayId()
                    val comp = lastFgComponent
                    if (comp != null) {
                        root?.relaunchFullscreen(disp, comp)
                        Log.i(TAG, "dex fullscreen fallback " + comp + " on display " + disp)
                    }
                }
            }
            "key_combo" -> {
                val disp = targetDisplayId()
                root?.pointCombo(disp, value.ifBlank { "ctrl+alt+f" })
                Log.i(TAG, "key_combo " + value + " -> display " + disp)
            }
            "home" -> fireGlobalKey(KeyEvent.KEYCODE_HOME)
            "recents" -> fireGlobalKey(KeyEvent.KEYCODE_APP_SWITCH)
            else -> ActionDispatcher.run(this, prefs, action, value, "")
        }
        haptic(30L)
    }

    /** full-key + combo mapping. returns true when the key was consumed */
    private fun handleMappedButton(keyCode: Int, action: Int): Boolean {
        if (action == KeyEvent.ACTION_DOWN) {
            Log.i(TAG, "mapped key " + keyCode + " name=" + (Prefs.keycodeButton(keyCode) ?: "?") +
                " type=" + (prefs.getString(Prefs.btnType(Prefs.keycodeButton(keyCode) ?: ""), "default")))
        }
        if (action == KeyEvent.ACTION_UP) {
            pressedButtons.remove(keyCode)
            return false
        }
        if (action != KeyEvent.ACTION_DOWN) return false
        pressedButtons.add(keyCode)
        // 1) combos first (all listed buttons must be held)
        for (i in 0 until Prefs.COMBO_COUNT) {
            val keys = prefs.getString(Prefs.comboKeys(i), "") ?: ""
            if (keys.isBlank()) continue
            val codes = keys.split("+").mapNotNull { Prefs.buttonKeycode(it.trim()) }
            if (codes.isEmpty()) continue
            val type = prefs.getString(Prefs.comboType(i), "none") ?: "none"
            if (type == "none" || type == "default") continue
            if (codes.all { pressedButtons.contains(it) }) {
                if (firedCombos.add(i)) {
                    fireAction(type, prefs.getString(Prefs.comboValue(i), "") ?: "")
                }
                return true
            }
        }
        // 2) single button mapping
        val name = Prefs.keycodeButton(keyCode) ?: return false
        val type = prefs.getString(Prefs.btnType(name), "default") ?: "default"
        if (type != "default" && type != "none") {
            fireAction(type, prefs.getString(Prefs.btnValue(name), "") ?: "")
            return true
        }
        return false
    }

    // ------------------------------------------------------------- key input
    private fun handleKey(keyCode: Int, action: Int, repeat: Int): Boolean {
        val e = engine ?: return false
        // user remaps win over the built-in behaviour; combos are checked inside
        if (handleMappedButton(keyCode, action)) return true
        if (action == KeyEvent.ACTION_UP) firedCombos.clear()
        val toggleKey = Prefs.toggleKeycode(prefs)
        val toggleEnabled = prefs.getBoolean(Prefs.TOGGLE_ENABLED, true)

        // ----- toggle key ------------------------------------------------
        if (keyCode == toggleKey && toggleEnabled) {
            val longPressMs = Prefs.l3LongPress(prefs) * 100L
            if (!mouseMode) {
                when (action) {
                    KeyEvent.ACTION_DOWN -> {
                        if (longPressMs > 0) {
                            pendingToggle = true
                            toggleLongFired = false
                            handler.postDelayed(longPressRunnable, longPressMs)
                            return true
                        }
                        toggleMouseMode(true)
                    }
                    KeyEvent.ACTION_UP -> if (pendingToggle) {
                        pendingToggle = false
                        handler.removeCallbacks(longPressRunnable)
                        if (!toggleLongFired) toggleMouseMode(true)
                    }
                }
            } else {
                if (action == KeyEvent.ACTION_DOWN) toggleMouseMode(false)
            }
            haptic(50L)
            return true
        }

        // BUTTON_MODE also toggles (matching the original)
        if (keyCode == KeyEvent.KEYCODE_BUTTON_MODE) {
            if (action == KeyEvent.ACTION_DOWN) toggleMouseMode(!mouseMode)
            return true
        }

        // START / SELECT work in both modes
        if (keyCode == KeyEvent.KEYCODE_BUTTON_START) {
            if (action == KeyEvent.ACTION_DOWN) {
                ActionDispatcher.run(this, prefs, "home", "")
                haptic(50L)
            }
            return true
        }
        if (keyCode == KeyEvent.KEYCODE_BUTTON_SELECT) {
            if (action == KeyEvent.ACTION_DOWN) {
                ActionDispatcher.run(this, prefs, "recents", "")
                haptic(50L)
            }
            return true
        }

        if (!e.enabled) {
            // only the toggle matters when mouse mode is off: do NOT swallow the
            // key, the game in front still needs its controller
            return false
        }

        // the original lets BACK through untouched; with the controller grabbed
        // we have to re-inject it through the virtual keyboard
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            val linux = KeyMap.toLinux(KeyEvent.KEYCODE_BACK)
            if (root?.isRunning == true && linux != null) {
                root?.key(linux, action == KeyEvent.ACTION_DOWN)
            }
            return true
        }


        val swap = prefs.getBoolean(Prefs.SWAP_AB, false)
        val primary = if (swap) KeyEvent.KEYCODE_BUTTON_B else KeyEvent.KEYCODE_BUTTON_A
        val secondary = if (swap) KeyEvent.KEYCODE_BUTTON_A else KeyEvent.KEYCODE_BUTTON_B

        if (keyCode == primary) {
            when (action) {
                KeyEvent.ACTION_DOWN -> if (repeat == 0) e.onPrimaryDown()
                KeyEvent.ACTION_UP -> e.onPrimaryUp()
            }
            return true
        }
        if (keyCode == secondary) {
            if (action == KeyEvent.ACTION_DOWN) {
                ActionDispatcher.back(this)
                haptic(50L)
            }
            return true
        }
        if (keyCode == KeyEvent.KEYCODE_BUTTON_X) {
            modifierHeld = action == KeyEvent.ACTION_DOWN
            return true
        }
        val down = action == KeyEvent.ACTION_DOWN
        when (keyCode) {
            // mapping slots, only while X (the modifier) is held - same as original
            KeyEvent.KEYCODE_BUTTON_L1 -> if (modifierHeld) onSlot("lb", down) else if (down) mediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            KeyEvent.KEYCODE_BUTTON_R1 -> if (modifierHeld) onSlot("rb", down) else if (down) mediaKey(KeyEvent.KEYCODE_MEDIA_NEXT)
            KeyEvent.KEYCODE_BUTTON_L2 -> if (modifierHeld) onSlot("lt", down)
            KeyEvent.KEYCODE_BUTTON_R2 -> if (modifierHeld) onSlot("rt", down)
            KeyEvent.KEYCODE_DPAD_LEFT ->
                if (modifierHeld) onSlot("left", down) else dpadKey(KeyEvent.KEYCODE_DPAD_LEFT, down)
            KeyEvent.KEYCODE_DPAD_RIGHT ->
                if (modifierHeld) onSlot("right", down) else dpadKey(KeyEvent.KEYCODE_DPAD_RIGHT, down)
            KeyEvent.KEYCODE_DPAD_UP ->
                if (modifierHeld) onSlot("up", down) else dpadKey(KeyEvent.KEYCODE_DPAD_UP, down)
            KeyEvent.KEYCODE_DPAD_DOWN ->
                if (modifierHeld) onSlot("down", down) else dpadKey(KeyEvent.KEYCODE_DPAD_DOWN, down)
            KeyEvent.KEYCODE_BUTTON_Y -> if (down) mediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            KeyEvent.KEYCODE_BUTTON_THUMBR -> if (down) toggleDisplay()
        }
        return true
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        val src = event.source
        val isGamepad = (src and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD ||
            (src and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK ||
            (src and InputDevice.SOURCE_DPAD) == InputDevice.SOURCE_DPAD
        if (!isGamepad) return super.onKeyEvent(event)
        // when the root helper is alive it is the authoritative input source;
        // handling the same key twice would toggle the mode twice
        if (root?.isRunning == true) return super.onKeyEvent(event)
        Log.d(TAG, "key ${event.keyCode} action=${event.action} src=$src")
        return handleKey(event.keyCode, event.action, event.repeatCount)
    }

    // --------------------------------------------------- fallback input views
    /**
     * Without root the gamepad MotionEvents only reach a focused window, so we
     * add a tiny focusable accessibility overlay on every active display and
     * read the axes from it (exactly what the original app does).
     */
    private fun updateFocusCatchers() {
        if (useRoot) {
            removeFocusViews()
            return
        }
        val wanted = listOfNotNull(display)
        val wantedIds = wanted.map { it.displayId }.toSet()
        focusViews.keys.filter { it !in wantedIds }.forEach { id ->
            focusViews.remove(id)?.let { (v, wm) ->
                try {
                    wm.removeView(v)
                } catch (_: Throwable) {
                }
            }
        }
        for (d in wanted) {
            if (focusViews.containsKey(d.displayId)) continue
            try {
                val ctx = createDisplayContext(d)
                val wm = try {
                    ctx.createWindowContext(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, null)
                        .getSystemService(Context.WINDOW_SERVICE) as WindowManager
                } catch (_: Throwable) {
                    ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                }
                val view = GamepadView(ctx)
                val lp = WindowManager.LayoutParams(
                    15, 15,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    android.graphics.PixelFormat.TRANSLUCENT,
                )
                lp.gravity = Gravity.START or Gravity.TOP
                wm.addView(view, lp)
                focusViews[d.displayId] = view to wm
                view.post { view.requestFocus() }
            } catch (t: Throwable) {
                Log.w(TAG, "focus catcher on ${d.displayId} failed: ${t.message}")
            }
        }
    }

    private fun removeFocusViews() {
        focusViews.values.forEach { (v, wm) ->
            try {
                wm.removeView(v)
            } catch (_: Throwable) {
            }
        }
        focusViews.clear()
    }

    private inner class GamepadView(context: Context) : View(context) {
        override fun onGenericMotionEvent(event: MotionEvent): Boolean {
            Log.d(TAG, "motion action=${event.action} src=${event.source} ax0=${event.getAxisValue(MotionEvent.AXIS_X)}")
            val src = event.source
            if ((src and InputDevice.SOURCE_JOYSTICK) != InputDevice.SOURCE_JOYSTICK &&
                (src and InputDevice.SOURCE_GAMEPAD) != InputDevice.SOURCE_GAMEPAD
            ) {
                return super.onGenericMotionEvent(event)
            }
            if (event.action == MotionEvent.ACTION_OUTSIDE) {
                // a real touch elsewhere on the display - the original app
                // treats this as "user took over" and sleeps
                Log.i(TAG, "focus lost to outside touch on display ${this.display?.displayId}")
                if (mouseMode) toggleMouseMode(false)
                return false
            }
            if (event.action != MotionEvent.ACTION_MOVE) return super.onGenericMotionEvent(event)
            for (axis in intArrayOf(
                MotionEvent.AXIS_X, MotionEvent.AXIS_Y,
                MotionEvent.AXIS_Z, MotionEvent.AXIS_RX, MotionEvent.AXIS_RZ, MotionEvent.AXIS_RY,
                MotionEvent.AXIS_HAT_X, MotionEvent.AXIS_HAT_Y,
                MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER,
                MotionEvent.AXIS_BRAKE, MotionEvent.AXIS_GAS,
            )) {
                handleAxis(axis, event.getAxisValue(axis))
            }
            return true
        }

        override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
            return handleViewKey(event)
        }

        override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
            return handleViewKey(event)
        }

        /** DeX disables the accessibility keyboard interceptor, so the focused
         *  overlay is the only way to see gamepad buttons there. */
        private fun handleViewKey(event: KeyEvent): Boolean {
            val src = event.source
            val isPad = (src and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD ||
                (src and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK ||
                (src and InputDevice.SOURCE_DPAD) == InputDevice.SOURCE_DPAD ||
                (src and InputDevice.SOURCE_KEYBOARD) == InputDevice.SOURCE_KEYBOARD
            if (!isPad) return false
            handleKey(event.keyCode, event.action, event.repeatCount)
            return true
        }

        @Suppress("UNUSED_PARAMETER")
        override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
            return super.dispatchGenericMotionEvent(event)
        }
    }

    // -------------------------------------------------------------- haptics
    private fun haptic(ms: Long) {
        if (!prefs.getBoolean(Prefs.HAPTIC, true)) return
        try {
            val amplitude = Prefs.vibration(prefs).coerceIn(1, 255)
            val ids = InputDevice.getDeviceIds()
            for (id in ids) {
                val dev = InputDevice.getDevice(id) ?: continue
                if (!dev.supportsSource(InputDevice.SOURCE_GAMEPAD) && !dev.supportsSource(InputDevice.SOURCE_JOYSTICK)) continue
                if (Build.VERSION.SDK_INT >= 31) {
                    val vib = dev.vibrator
                    if (vib != null && vib.hasVibrator()) {
                        vib.vibrate(VibrationEffect.createOneShot(ms, amplitude))
                        return
                    }
                }
            }
            val vib = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            val v = vib ?: return
            if (v.hasVibrator()) v.vibrate(VibrationEffect.createOneShot(ms, amplitude))
        } catch (_: Throwable) {
        }
    }

    // ------------------------------------------------------------ prefs react
    private val prefListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        handler.post {
            val e = engine ?: return@post
            when (key) {
                Prefs.SCROLL_SPEED -> e.scrollSpeed = Prefs.scrollSpeed(prefs)
                Prefs.MOUSE_SIZE -> {
                    e.setCursorSize(Prefs.mouseSize(prefs))
                    if (e.enabled) {
                        toggleMouseMode(false)
                        toggleMouseMode(true)
                    }
                }
                Prefs.MOUSE_TIMEOUT -> e.setTimeoutSeconds(Prefs.timeoutSeconds(prefs))
                Prefs.CURSOR_COLOR, Prefs.CURSOR_STYLE -> if (e.enabled) {
                    toggleMouseMode(false)
                    toggleMouseMode(true)
                }
                Prefs.NATIVE_POINTER -> if (e.enabled) {
                    toggleMouseMode(false)
                    toggleMouseMode(true)
                }
                Prefs.FORCE_MIRRORING -> pickDisplay()
                Prefs.MOUSE_ENABLED -> if (!prefs.getBoolean(Prefs.MOUSE_ENABLED, true)) toggleMouseMode(false)
            }
        }
    }

    companion object {
        private const val TAG = "GpmService"
        const val ACTION_STATE = "com.dennis.gamepadmouse.STATE"
        const val ACTION_TOGGLE = "com.dennis.gamepadmouse.TOGGLE"
        const val ACTION_SNAP = "com.dennis.gamepadmouse.SNAP"
        const val ACTION_DEBUG = "com.dennis.gamepadmouse.DEBUG"
        const val EXTRA_MOUSE_ON = "mouse_on"
    }
}

/** the live service instance, used by debug broadcasts */
internal var gpmService: MouseAccessibilityService? = null
