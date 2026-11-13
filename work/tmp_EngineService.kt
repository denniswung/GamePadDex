package com.dennis.dexpad

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Display
import android.view.KeyEvent
import java.io.File

/**
 * Mapping engine: turns the helper's raw gamepad stream into a DeX mouse.
 *
 * Runs as a foreground service (started at boot by the KernelSU module) and stays
 * connected to the root helper. All input arrives from the helper because the
 * helper owns the controller with EVIOCGRAB, so this service needs no
 * accessibility service and no permissions beyond a notification.
 */
class EngineService : Service(), RootInput.Listener {

    companion object {
        private const val TAG = "DexPad"
        private const val CHANNEL_ID = "dexpad_engine"
        private const val NOTIFICATION_ID = 1001

        const val SOCKET_PATH = "/data/data/com.dennis.dexpad/files/gpm.sock"

        fun ensureRunning(context: Context) {
            try {
                val i = Intent(context, EngineService::class.java)
                if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(i)
                else context.startService(i)
            } catch (t: Throwable) {
                Log.w(TAG, "ensureRunning failed: ${t.message}")
            }
        }
    }

    private lateinit var prefs: Prefs
    private lateinit var root: RootInput
    private lateinit var displayManager: DisplayManager
    private val handler = Handler(Looper.getMainLooper())
    /** dedicated high-priority thread for the 8 ms mapping loop */
    private var engineThread: HandlerThread? = null
    private var engineHandler: Handler? = null
    private val axes = FloatArray(40)

    private var modeOn = false
    private var wheelAcc = 0f
    private var wheelHold = 0
    private var lastWheelHoldAt = 0L
    private var ticks = 0L
    private var lastSpawnAt = 0L
    private var debugLogs = true
    /** display id of the wired DeX monitor, -1 when not connected */
    private var dexDisplayId = -1
    /** buttons currently held (keys + axis-derived dpad/triggers) */
    private val pressedButtons = HashSet<String>()
    /** mouse buttons currently held (0=left 1=right 2=middle) */
    private val pressedMouse = HashSet<Int>()
    private var dpadX = 0f
    private var dpadY = 0f
    private var ltDown = false
    private var rtDown = false
    /** horizontal swipe direction (button action) + throttle timestamps */
    private var hScrollDir = 0
    private var lastHSwipeAt = 0L
    private var lastHScrollBtnAt = 0L
    /** stick has returned to the centre since the last swipe */
    private var hSwipeArmed = true
    /** one horizontal gesture is in flight until this timestamp */
    private var swipeCooldownUntil = 0L
    /** LT/RT zoom: -1 out, +1 in, 0 idle; repeated while held */
    private var zoomHold = 0
    private var lastZoomAt = 0L
    /** after "光标居中": ignore stick motion until it returns to neutral (or timeout) */
    private var centerLock = false
    private var centerLockUntil = 0L
    /** right after an arrow key: keep the pointer still so hover does not steal the focus back */
    private var arrowLockUntil = 0L
    private var lastTickAt = 0L
    /** one-shot single actions that wait for release because the button is in a mix */
    private val deferredSingles = HashMap<String, String>()
    /** hold-type actions of mix keys that wait briefly before starting */
    private val pendingHolds = HashMap<String, Runnable>()
    /** buttons that currently have a hold-type action running */
    private val startedHolds = HashSet<String>()
    /** buttons whose deferred single was claimed by a mix and must not fire */
    private val mixConsumed = HashSet<String>()
    private val mixFired = BooleanArray(Prefs.MIX_COUNT)
    private val MIX_HOLD_DELAY = 150L
    /** double-press support: the first press waits this long for a second tap */
    private val pendingDowns = HashMap<String, Runnable>()
    private val lastDownAt = HashMap<String, Long>()
    private val DOUBLE_WINDOW = 320L

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        when (key) {
            Prefs.KEY_ENABLED, Prefs.KEY_AUTO_DEX -> {
                applyDesiredMode()
                if (key == Prefs.KEY_AUTO_DEX) refreshDeX()
            }
            else -> {
            }
        }
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = refreshDeX()
        override fun onDisplayRemoved(displayId: Int) = refreshDeX()
        override fun onDisplayChanged(displayId: Int) = refreshDeX()
    }

    private val tick = object : Runnable {
        override fun run() {
            try {
                step()
            } catch (t: Throwable) {
                Log.e(TAG, "tick failed", t)
            }
            engineHandler?.postDelayed(this, 8L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        EngineState.serviceRunning = true
        prefs = Prefs(this)
        createChannel()
        goForeground()
        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        try {
            displayManager.registerDisplayListener(displayListener, handler)
        } catch (t: Throwable) {
            Log.w(TAG, "display listener: ${t.message}")
        }
        prefs.shared.registerOnSharedPreferenceChangeListener(prefsListener)
        root = RootInput(SOCKET_PATH, this)
        root.start()
        // run the mapping loop on its own thread at display priority: the main
        // thread can be busy with app lifecycle / notifications and the 16 ms
        // cadence was visible as input lag
        val t = HandlerThread("dexpad-engine", android.os.Process.THREAD_PRIORITY_URGENT_DISPLAY)
        t.start()
        engineThread = t
        engineHandler = Handler(t.looper)
        engineHandler?.post(tick)
        refreshDeX()
        Log.i(TAG, "engine started, socket=$SOCKET_PATH")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        refreshDeX()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * The config page can be dismissed (recents swipe, back, etc.) without the
     * mapping engine stopping: re-request the service right away and, if the
     * process gets killed anyway, the root supervisor (gpm_dex/service.sh)
     * restarts it within a few seconds.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "task removed, keeping engine alive")
        try {
            startForegroundService(Intent(this, EngineService::class.java))
        } catch (t: Throwable) {
            Log.w(TAG, "restart after task removal failed: ${t.message}")
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        Log.i(TAG, "engine stopping")
        handler.removeCallbacks(tick)
        try {
            prefs.shared.unregisterOnSharedPreferenceChangeListener(prefsListener)
        } catch (_: Throwable) {
        }
        try {
            displayManager.unregisterDisplayListener(displayListener)
        } catch (_: Throwable) {
        }
        try {
            root.stop()
        } catch (_: Throwable) {
        }
        try {
            engineThread?.quitSafely()
        } catch (_: Throwable) {
        }
        EngineState.serviceRunning = false
        EngineState.connected = false
        EngineState.modeOn = false
        super.onDestroy()
    }

    // ------------------------------------------------------------- lifecycle

    private fun createChannel() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            val ch = NotificationChannel(CHANNEL_ID, "手柄映射", NotificationManager.IMPORTANCE_LOW)
            ch.setShowBadge(false)
            nm.createNotificationChannel(ch)
        }
    }

    private fun buildNotification(text: String): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("手柄映射")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_stat)
            .setOngoing(true)
            .build()
    }

    private fun goForeground() {
        try {
            val n = buildNotification("正在连接手柄…")
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, n)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "startForeground failed: ${t.message}")
        }
    }

    private fun updateNotification() {
        val text = when {
            !EngineState.connected -> "正在等待 root 助手…"
            EngineState.modeOn -> "鼠标模式：开 · 手柄已独占"
            else -> "鼠标模式：关 · 手柄已交还系统"
        }
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification(text))
        } catch (t: Throwable) {
            Log.w(TAG, "notify failed: ${t.message}")
        }
    }

    // ----------------------------------------------------------------- input

    override fun onAxis(axis: Int, value: Float) {
        if (axis !in axes.indices) return
        axes[axis] = value
        // the helper reports the D-pad as HAT axes and the analog triggers as
        // LTRIGGER/RTRIGGER (or GAS/BRAKE on pads without a right stick)
        when (axis) {
            15 -> onDpadAxis(true, value)
            16 -> onDpadAxis(false, value)
            17, 22 -> onTrigger("lt", value)
            18, 23 -> onTrigger("rt", value)
        }
    }

    private fun onDpadAxis(horizontal: Boolean, value: Float) {
        val old = if (horizontal) dpadX else dpadY
        if (old == value) return
        if (horizontal) dpadX = value else dpadY = value
        val negative = if (horizontal) "left" else "up"
        val positive = if (horizontal) "right" else "down"
        if (old < -0.5f) handleButton(negative, false)
        if (old > 0.5f) handleButton(positive, false)
        if (value < -0.5f) handleButton(negative, true)
        if (value > 0.5f) handleButton(positive, true)
    }

    private fun onTrigger(name: String, value: Float) {
        val pressed = value > 0.5f
        val was = if (name == "lt") ltDown else rtDown
        if (pressed == was) return
        if (name == "lt") ltDown = pressed else rtDown = pressed
        handleButton(name, pressed)
    }

    override fun onKey(keyCode: Int, action: Int) {
        val name = buttonName(keyCode) ?: return
        handleButton(name, action == 0)
    }

    /** common path for key-based and axis-based (dpad/trigger) buttons */
    private fun handleButton(name: String, down: Boolean) {
        // axis-derived buttons can report the same state twice (GAS+BRAKE pads),
        // and key events could repeat: only act on real transitions
        val wasDown = pressedButtons.contains(name)
        if (down == wasDown) return
        if (down) pressedButtons.add(name) else pressedButtons.remove(name)

        if (down) {
            Log.i(TAG, "button $name down mapped=${prefs.action(name)} mode=$modeOn ready=${root.helperReady}")
            // a button with a double-press action delays its single action by
            // the double window; a second press inside the window fires the
            // double action and cancels the single
            val dbl = prefs.doubleAction(name)
            if (dbl != Action.NONE) {
                val pending = pendingDowns.remove(name)
                val now = SystemClock.elapsedRealtime()
                val last = lastDownAt[name] ?: 0L
                if (pending != null && now - last <= DOUBLE_WINDOW) {
                    handler.removeCallbacks(pending)
                    lastDownAt[name] = 0L
                    Log.i(TAG, "double $name -> $dbl")
                    if (modeOn && root.helperReady) {
                        if (dbl == Action.KEY_COMBO) fireSystemAction(dbl, prefs.combo(name))
                        else fireSystemAction(dbl, "")
                    }
                    return
                }
                lastDownAt[name] = now
                val cb = Runnable {
                    pendingDowns.remove(name)
                    processDown(name)
                }
                pendingDowns[name] = cb
                handler.postDelayed(cb, DOUBLE_WINDOW)
                return
            }
            processDown(name)
        } else {
            releaseMixFor(name)
            val consumed = mixConsumed.remove(name)
            pendingHolds.remove(name)?.let { handler.removeCallbacks(it) }
            val deferred = deferredSingles.remove(name)
            if (deferred != null) {
                if (consumed) {
                    Log.i(TAG, "single $deferred cancelled (button was used as modifier)")
                } else if (modeOn && root.helperReady) {
                    Log.i(TAG, "single $deferred fired on release")
                    fireSingle(name, deferred)
                }
            }
            val mapped = prefs.action(name)
            if (startedHolds.remove(name)) {
                releaseActions(name, mapped)
            }
            if (mapped == Action.NONE || mapped == Action.TOGGLE) return
        }
    }

    /** the action side of a button press (delayed by DOUBLE_WINDOW when the button has a double action) */
    private fun processDown(name: String) {
        if (fireMix()) return
        if (mixConsumed.contains(name)) {
            Log.i(TAG, "single for $name skipped (mix consumed)")
            return
        }
        val mapped = prefs.action(name)
        if (mapped == Action.NONE) return
        if (mapped == Action.TOGGLE) {
            setMode(!modeOn)
            Log.i(TAG, "toggle -> mouse mode $modeOn")
            return
        }
        if (!modeOn || !root.helperReady) return
        if (!pressedButtons.contains(name)) {
            // released while waiting for a possible double tap: fire the
            // one-shot single action now
            if (isOneShot(mapped)) {
                Log.i(TAG, "single $mapped fired (after double window)")
                fireSingle(name, mapped)
            }
            return
        }
        // A button that also belongs to a mix slot does not fire its action
        // while it is held: one-shot actions wait for release, hold-type
        // actions (mouse button / wheel / zoom) start after a short grace
        // period so a chord can claim the press instead.
        if (inAnyMix(name)) {
            if (isOneShot(mapped)) {
                deferredSingles[name] = mapped
                Log.i(TAG, "single $mapped deferred (mix key $name)")
            } else {
                scheduleHold(name, mapped)
            }
        } else {
            fireSingle(name, mapped)
        }
    }

    /** mix key with a hold-type action: start it only after a short grace */
    private fun scheduleHold(name: String, mapped: String) {
        val r = Runnable {
            pendingHolds.remove(name)
            if (modeOn && root.helperReady && !mixConsumed.contains(name)) {
                startedHolds.add(name)
                fireSingle(name, mapped)
            }
        }
        pendingHolds[name] = r
        handler.postDelayed(r, MIX_HOLD_DELAY)
    }

    /** release the hold-type action a button started */
    private fun releaseActions(name: String, mapped: String) {
        if (mapped == Action.NONE || mapped == Action.TOGGLE) return
        if (!modeOn || !root.helperReady) return
        when (mapped) {
            Action.LEFT -> {
                root.button(0, false)
                pressedMouse.remove(0)
            }
            Action.RIGHT -> {
                root.button(1, false)
                pressedMouse.remove(1)
            }
            Action.MIDDLE -> {
                root.button(2, false)
                pressedMouse.remove(2)
            }
            Action.WHEEL_UP, Action.WHEEL_DOWN -> wheelHold = 0
            Action.WHEEL_LEFT, Action.WHEEL_RIGHT -> hScrollDir = 0
            Action.ZOOM_IN, Action.ZOOM_OUT -> zoomHold = 0
            else -> {
            }
        }
    }

    /** actions that fire once and do not need press/hold semantics */
    private fun isOneShot(action: String): Boolean = when (action) {
        Action.LEFT, Action.RIGHT, Action.MIDDLE,
        Action.WHEEL_UP, Action.WHEEL_DOWN, Action.WHEEL_LEFT, Action.WHEEL_RIGHT,
        Action.ZOOM_IN, Action.ZOOM_OUT, Action.TOGGLE, Action.NONE -> false
        else -> true
    }

    private fun fireSingle(name: String, mapped: String) {
        when (mapped) {
            Action.LEFT -> {
                root.button(0, true)
                pressedMouse.add(0)
                Log.i(TAG, "left button down")
            }
            Action.RIGHT -> {
                root.button(1, true)
                pressedMouse.add(1)
            }
            Action.MIDDLE -> {
                root.button(2, true)
                pressedMouse.add(2)
            }
            Action.WHEEL_UP -> wheelHold = 1
            Action.WHEEL_DOWN -> wheelHold = -1
            Action.WHEEL_LEFT -> hScrollDir = 1
            Action.WHEEL_RIGHT -> hScrollDir = -1
            Action.ZOOM_IN -> {
                zoomHold = 1
                lastZoomAt = 0L
            }
            Action.ZOOM_OUT -> {
                zoomHold = -1
                lastZoomAt = 0L
            }
            else -> fireSystemAction(mapped, prefs.combo(name))
        }
        if (!isOneShot(mapped) && mapped != Action.TOGGLE) startedHolds.add(name)
    }

    /** true when a mix slot with an action was completed by the current press */
    private fun fireMix(): Boolean {
        for (i in 0 until Prefs.MIX_COUNT) {
            if (mixFired[i]) continue
            val keys = prefs.mixKeys(i)
            if (keys.size < 2) continue
            val action = prefs.mixAction(i)
            if (action == Action.NONE) continue
            if (keys.any { !pressedButtons.contains(it) }) continue
            mixFired[i] = true
            for (k in keys) {
                pendingHolds.remove(k)?.let { handler.removeCallbacks(it) }
                deferredSingles.remove(k)
                // also cover buttons whose press handling is still delayed by
                // the double-tap window
                mixConsumed.add(k)
                if (startedHolds.remove(k)) {
                    // a hold-type action already began: stop it
                    releaseActions(k, prefs.action(k))
                }
            }
            Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action")
            fireMixAction(action, prefs.mixValue(i))
            return true
        }
        return false
    }

    private fun releaseMixFor(name: String) {
        for (i in 0 until Prefs.MIX_COUNT) {
            if (mixFired[i] && prefs.mixKeys(i).contains(name)) mixFired[i] = false
        }
    }

    private fun inAnyMix(name: String): Boolean {
        for (i in 0 until Prefs.MIX_COUNT) {
            val keys = prefs.mixKeys(i)
            if (keys.size >= 2 && prefs.mixAction(i) != Action.NONE && keys.contains(name)) return true
        }
        return false
    }

    /** one-shot action triggered by a mix slot (no hold semantics) */
    private fun fireMixAction(action: String, comboValue: String) {
        if (!modeOn || !root.helperReady) return
        when (action) {
            Action.LEFT -> {
                root.button(0, true)
                root.button(0, false)
            }
            Action.RIGHT -> {
                root.button(1, true)
                root.button(1, false)
            }
            Action.MIDDLE -> {
                root.button(2, true)
                root.button(2, false)
            }
            Action.WHEEL_UP -> root.wheel(3)
            Action.WHEEL_DOWN -> root.wheel(-3)
            Action.WHEEL_LEFT -> fireSwipeOnce(1)
            Action.WHEEL_RIGHT -> fireSwipeOnce(-1)
            Action.TOGGLE -> setMode(!modeOn)
            else -> fireSystemAction(action, comboValue)
        }
    }

    /** releases everything we may be holding (mouse button / wheel hold / axis state) */
    private fun releaseHeld() {
        for (b in pressedMouse.toList()) {
            root.button(b, false)
        }
        pressedMouse.clear()
        pressedButtons.clear()
        deferredSingles.clear()
        for (r in pendingHolds.values) handler.removeCallbacks(r)
        pendingHolds.clear()
        for (r in pendingDowns.values) handler.removeCallbacks(r)
        pendingDowns.clear()
        lastDownAt.clear()
        startedHolds.clear()
        mixConsumed.clear()
        mixFired.fill(false)
        dpadX = 0f
        dpadY = 0f
        ltDown = false
        rtDown = false
        wheelHold = 0
        hScrollDir = 0
        hSwipeArmed = true
        zoomHold = 0
    }

    /** one-shot system actions injected through the root helper on the DeX display */
    private fun fireSystemAction(action: String, comboValue: String) {
        val display = if (EngineState.dexConnected && dexDisplayId >= 0) dexDisplayId else 0
        when (action) {
            Action.RECENTS -> {
                root.pointKey(display, KeyEvent.KEYCODE_APP_SWITCH)
                Log.i(TAG, "recents on display $display")
            }
            Action.HOME -> {
                root.pointKey(display, KeyEvent.KEYCODE_HOME)
                Log.i(TAG, "home on display $display")
            }
            Action.BACK -> {
                root.pointKey(display, KeyEvent.KEYCODE_BACK)
                Log.i(TAG, "back on display $display")
            }
            Action.NOTIFICATIONS -> {
                root.notifyPanel()
                Log.i(TAG, "notification panel")
            }
            Action.ARROW_UP, Action.ARROW_DOWN, Action.ARROW_LEFT, Action.ARROW_RIGHT -> {
                val code = when (action) {
                    Action.ARROW_UP -> KeyEvent.KEYCODE_DPAD_UP
                    Action.ARROW_DOWN -> KeyEvent.KEYCODE_DPAD_DOWN
                    Action.ARROW_LEFT -> KeyEvent.KEYCODE_DPAD_LEFT
                    else -> KeyEvent.KEYCODE_DPAD_RIGHT
                }
                root.pointKey(display, code)
                // arrow keys move the focus/selection; keep the pointer still
                // for a moment, otherwise the hover event immediately pulls the
                // focus back to the cursor area and the key looks ignored
                arrowLockUntil = SystemClock.elapsedRealtime() + 300
                Log.i(TAG, "arrow key $code on display $display")
            }
            Action.KEY_COMBO -> {
                val codes = KeyCombo.parse(comboValue)
                if (codes.isEmpty()) {
                    Log.w(TAG, "key combo '$comboValue' has no valid keys")
                    return
                }
                root.keyCombo(display, codes)
                Log.i(TAG, "key combo '$comboValue' -> $codes on display $display")
            }
            // DeX window shortcuts taken from the DeX "键盘快捷键" page
            // DeX ignores injected CMD+= / CMD+[ / CMD+] (the shortcut service
            // filters synthetic meta chords), so resize the focused task
            // directly through `am task resize` in the root helper.
            Action.MAXIMIZE -> {
                root.arrangeWindow(display, "max")
                Log.i(TAG, "maximize window on display $display")
            }
            Action.MINIMIZE -> dexCombo(display, "minimize", KeyEvent.KEYCODE_META_LEFT, KeyEvent.KEYCODE_MINUS)
            Action.SNAP_LEFT -> {
                root.arrangeWindow(display, "left")
                Log.i(TAG, "snap window left on display $display")
            }
            Action.SNAP_RIGHT -> {
                root.arrangeWindow(display, "right")
                Log.i(TAG, "snap window right on display $display")
            }
            Action.CLOSE_WINDOW -> dexCombo(display, "close window", KeyEvent.KEYCODE_ALT_LEFT, KeyEvent.KEYCODE_F4)
            Action.TOGGLE_DEX -> dexCombo(display, "toggle DeX", KeyEvent.KEYCODE_META_LEFT, KeyEvent.KEYCODE_W)
            Action.SCREENSHOT -> dexCombo(display, "screenshot", KeyEvent.KEYCODE_ALT_LEFT, KeyEvent.KEYCODE_SYSRQ)
            Action.CENTER_CURSOR -> {
                val (w, h) = displaySize(display)
                centerLock = true
                centerLockUntil = SystemClock.elapsedRealtime() + 3000
                root.centerCursor(w, h)
                Log.i(TAG, "cursor centered on ${w}x$h")
            }
            Action.SWITCH_APP -> {
                root.switchApp(display)
                Log.i(TAG, "switch app on display $display")
            }
            // zoom = Ctrl + Plus / Ctrl + Minus (works in browsers and most apps)
            Action.ZOOM_IN -> dexCombo(display, "zoom in", KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_PLUS)
            Action.ZOOM_OUT -> dexCombo(display, "zoom out", KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.KEYCODE_MINUS)
            // media / volume keys; they act on the phone volume stream
            Action.VOLUME_UP -> {
                root.pointKey(display, KeyEvent.KEYCODE_VOLUME_UP)
                Log.i(TAG, "volume up on display $display")
            }
            Action.VOLUME_DOWN -> {
                root.pointKey(display, KeyEvent.KEYCODE_VOLUME_DOWN)
                Log.i(TAG, "volume down on display $display")
            }
            Action.VOLUME_MUTE -> {
                root.pointKey(display, KeyEvent.KEYCODE_VOLUME_MUTE)
                Log.i(TAG, "volume mute on display $display")
            }
            Action.PLAY_PAUSE -> {
                root.pointKey(display, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                Log.i(TAG, "play/pause on display $display")
            }
            Action.NEXT_TRACK -> {
                root.pointKey(display, KeyEvent.KEYCODE_MEDIA_NEXT)
                Log.i(TAG, "next track on display $display")
            }
            Action.PREV_TRACK -> {
                root.pointKey(display, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                Log.i(TAG, "previous track on display $display")
            }
        }
    }

    private fun dexCombo(display: Int, what: String, vararg codes: Int) {
        root.keyCombo(display, codes.toList())
        Log.i(TAG, "$what -> ${codes.toList()} on display $display")
    }

    private fun buttonName(keyCode: Int): String? = when (keyCode) {
        96 -> "a"
        97 -> "b"
        99 -> "x"
        100 -> "y"
        102 -> "lb"
        103 -> "rb"
        104 -> "lt"
        105 -> "rt"
        19 -> "up"
        20 -> "down"
        21 -> "left"
        22 -> "right"
        106 -> "l3"
        107 -> "r3"
        108 -> "start"
        109 -> "select"
        110 -> "guide"
        130 -> "share"   // KEY_RECORD (Xbox Share button) -> MEDIA_RECORD
        else -> null
    }

    private fun setMode(on: Boolean, force: Boolean = false) {
        if (!force && modeOn == on) return
        modeOn = on
        EngineState.modeOn = on
        if (!on) releaseHeld()
        if (root.helperReady) {
            if (on) root.grab() else root.ungrab()
        }
        updateNotification()
        Log.i(TAG, "mouse mode " + if (on) "ON" else "OFF")
    }

    /** true when the engine should own the controller right now */
    private fun desiredMode(): Boolean = prefs.enabled && (!prefs.autoDex || EngineState.dexConnected)

    private fun applyDesiredMode() {
        val want = desiredMode()
        if (want != modeOn) setMode(want, force = !want)
    }

    private fun step() {
        EngineState.modeOn = modeOn
        ticks++
        // the loop runs every 8 ms; speeds are expressed per 16 ms frame, so
        // scale by the real elapsed time to keep the pointer speed unchanged
        val nowMs = SystemClock.elapsedRealtime()
        val dtScale = if (lastTickAt == 0L) 0.5f
        else ((nowMs - lastTickAt).coerceIn(1L, 64L).toFloat() / 16f).coerceIn(0.1f, 4f)
        lastTickAt = nowMs
        if (ticks % 500 == 0L && !EngineState.connected) maybeSpawnHelper()
        if (!root.helperReady) return
        if (!modeOn) {
            wheelHold = 0
            hScrollDir = 0
            hSwipeArmed = true
            zoomHold = 0
            return
        }
        // right after "光标居中" ignore stick motion until the stick is back in
        // the dead zone (or a timeout) — otherwise the release of a slightly
        // deflected stick moves the pointer away again ("second jump")
        if (centerLock) {
            val dead = prefs.deadzone / 1000f
            if (SystemClock.elapsedRealtime() > centerLockUntil ||
                (Math.abs(axes[0]) < dead && Math.abs(axes[1]) < dead)
            ) {
                centerLock = false
            } else {
                return
            }
        }
        val dead = prefs.deadzone / 1000f
        val dx = curve(axes[0], dead)
        val dy = curve(axes[1], dead)
        if (dx != 0f || dy != 0f) {
            // X + left stick = precision mode: much slower pointer for aiming
            val precision = pressedButtons.contains("x")
            val scale = if (precision) prefs.precisionScale / 100f else 1f
            val speed = (if (EngineState.dexConnected) prefs.speedDex else prefs.speedPhone) * scale
            if (SystemClock.elapsedRealtime() >= arrowLockUntil) {
                root.move(dx * speed * dtScale, dy * speed * dtScale)
            }
        }

        // right stick -> wheel. A dedicated, larger dead zone (scroll_deadzone)
        // and a remap of [dead..1] to [0..1] keep a drifting or lightly touched
        // stick from scrolling, while still allowing fine slow scrolling.
        val scrollDead = prefs.scrollDeadzone / 1000f
        var sy = axes[13]                       // AXIS_RY
        if (Math.abs(sy) < 0.02f) sy = axes[14] // AXIS_RZ (pads without RX/RY)
        val ny = scrollCurve(sy, scrollDead)
        if (ny != 0f) {
            val invert = if (prefs.invertScroll) -1f else 1f
            wheelAcc += -ny * invert * (prefs.scrollSpeed * 0.05f) * dtScale
            val steps = wheelAcc.toInt()
            if (steps != 0) {
                wheelAcc -= steps
                root.wheel(steps)
            }
        } else {
            wheelAcc = 0f
        }

        // right stick X -> horizontal scrolling. REL_HWHEEL is ignored by many
        // touch-first apps (PiliPlus etc.), so this uses a real touch swipe
        // anchored at the mouse pointer instead (helper command V). One swipe
        // per push: the stick has to come back to the centre before the next
        // one fires, otherwise a held stick would flick through ten pages.
        var sx = axes[12]                       // AXIS_RX
        if (Math.abs(sx) < 0.02f) sx = axes[11] // AXIS_Z (pads without RX/RY)
        val nx = scrollCurve(sx, scrollDead)

        // A button whose single action is waiting for release (because it takes
        // part in combos) and that is held while a stick is used is acting as a
        // *modifier* — e.g. X + left stick = precision aiming. Its single action
        // must not fire when it is released afterwards.
        if (deferredSingles.isNotEmpty() &&
            (dx != 0f || dy != 0f || ny != 0f || nx != 0f)
        ) {
            for (k in deferredSingles.keys.toList()) {
                if (mixConsumed.add(k)) {
                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")
                }
            }
        }
        if (nx != 0f) {
            if (hSwipeArmed && SystemClock.elapsedRealtime() >= swipeCooldownUntil) {
                hSwipeArmed = false
                swipeStep(if (nx > 0) -1 else 1)
            }
        } else if (SystemClock.elapsedRealtime() >= swipeCooldownUntil) {
            hSwipeArmed = true
        }
        if (hScrollDir != 0) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastHScrollBtnAt >= 450) {
                lastHScrollBtnAt = now
                fireSwipeOnce(hScrollDir)
            }
        }

        if (wheelHold != 0) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastWheelHoldAt >= 80) {
                lastWheelHoldAt = now
                root.wheel(wheelHold)
            }
        }

        if (zoomHold != 0) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastZoomAt >= 250) {
                lastZoomAt = now
                fireSystemAction(
                    if (zoomHold > 0) Action.ZOOM_IN else Action.ZOOM_OUT,
                    "",
                )
            }
        }
    }

    /**
     * One horizontal swipe gesture. [dir] -1 = next page (finger moves left),
     * +1 = previous page.
     *
     * The gesture is deliberately constant (620 px in 260 ms, ~2380 px/s):
     * the previous version scaled the travel with the stick and used a fixed
     * duration, so the fling velocity changed from push to push and PiliPlus
     * animated the pages with the uneven "fast-slow-fast" feel. The cooldown
     * keeps a second drag from stacking on top of the page animation.
     */
    private fun swipeStep(dir: Int) {
        val now = SystemClock.elapsedRealtime()
        if (now < swipeCooldownUntil) return
        val display = if (EngineState.dexConnected && dexDisplayId >= 0) dexDisplayId else 0
        val (w, h) = displaySize(display)
        val dist = 620
        val ms = 260
        root.swipeH(display, dir * dist, ms, w, h)
        swipeCooldownUntil = now + ms + 170
        if (debugLogs) Log.i(TAG, "swipe $dir ${dist}px ${ms}ms on display $display")
    }

    private fun displaySize(id: Int): Pair<Int, Int> {
        val d = displayManager.getDisplay(id)
        val m = d?.mode
        return Pair(m?.physicalWidth ?: 2560, m?.physicalHeight ?: 1600)
    }

    /** one-shot horizontal swipe used by mix slots / wheel-left-right actions */
    private fun fireSwipeOnce(dir: Int) {
        val now = SystemClock.elapsedRealtime()
        if (now < swipeCooldownUntil) return
        val display = if (EngineState.dexConnected && dexDisplayId >= 0) dexDisplayId else 0
        val (w, h) = displaySize(display)
        val dist = 620
        val ms = 260
        root.swipeH(display, dir * dist, ms, w, h)
        swipeCooldownUntil = now + ms + 170
        if (debugLogs) Log.i(TAG, "swipe once $dir ${dist}px ${ms}ms on display $display")
    }

    private fun curve(v: Float, dead: Float): Float {
        val a = Math.abs(v)
        if (a <= dead) return 0f
        val n = ((a - dead) / (1f - dead)).coerceIn(0f, 1f)
        return Math.signum(v) * Math.pow(n.toDouble(), 2.5).toFloat()
    }

    /**
     * Scroll response: below [dead] nothing happens; above it the travel is
     * remapped to 0..1 so the first part of the range scrolls slowly and full
     * deflection is fast. The gentle gamma keeps the start of the range usable
     * (a small nudge above the dead zone already scrolls slowly instead of
     * sitting at a near-zero rate).
     */
    private fun scrollCurve(v: Float, dead: Float): Float {
        val a = Math.abs(v)
        if (a <= dead) return 0f
        val n = ((a - dead) / (1f - dead)).coerceIn(0f, 1f)
        return Math.signum(v) * Math.pow(n.toDouble(), 0.7).toFloat()
    }

    // ------------------------------------------------------------------ root

    override fun onReady() {
        EngineState.connected = true
        EngineState.lastError = ""
        EngineState.dexConnected = isDeX()
        if (desiredMode()) {
            modeOn = true
            EngineState.modeOn = true
            root.grab()
        } else {
            modeOn = false
            EngineState.modeOn = false
            root.ungrab()
        }
        updateNotification()
    }

    override fun onLinkLost() {
        EngineState.connected = false
        EngineState.modeOn = false
        modeOn = false
        wheelHold = 0
        releaseHeld()
        updateNotification()
    }

    override fun onDevicesChanged(devices: List<String>) {
        EngineState.devices = devices
    }

    // ------------------------------------------------------------ root helper

    /**
     * On this device KernelSU runs in late-load mode and does not execute module
     * boot scripts, so the helper may not be running when the phone boots. The
     * app is granted root once (KernelSU prompt) and can start the very same
     * helper itself; the helper's flock makes this safe against the KSU module
     * and against double starts.
     */
    private fun maybeSpawnHelper() {
        val now = SystemClock.elapsedRealtime()
        if (now - lastSpawnAt < 20000) return
        lastSpawnAt = now
        val bin = File(filesDir, "gpminput")
        if (!bin.exists() || bin.length() == 0L) {
            try {
                assets.open("gpminput").use { input ->
                    bin.outputStream().use { out -> input.copyTo(out) }
                }
                bin.setExecutable(true, false)
                Log.i(TAG, "helper binary extracted to ${bin.absolutePath}")
            } catch (t: Throwable) {
                Log.e(TAG, "cannot extract helper: ${t.message}")
                return
            }
        }
        Thread {
            val candidates = listOf("/system/bin/su", "/debug_ramdisk/su", "su")
            for (su in candidates) {
                try {
                    Log.i(TAG, "su candidate $su exists=${File(su).exists()} canExec=${File(su).canExecute()}")
                    val cmd = "${bin.absolutePath} --socket $SOCKET_PATH"
                    val p = ProcessBuilder(su, "-c", cmd)
                        .redirectErrorStream(true)
                        .start()
                    Log.i(TAG, "helper started via $su")
                    p.inputStream.bufferedReader().useLines { lines ->
                        lines.forEach { Log.i(TAG, "helper says: $it") }
                    }
                    return@Thread
                } catch (t: Throwable) {
                    Log.w(TAG, "start via $su failed: ${t.message}")
                }
            }
        }.apply { isDaemon = true }.start()
    }

    // ---------------------------------------------------------------- display

    /**
     * True only for a *real* external display (the wired DeX monitor).
     *
     * The Fold's inner display also reports FLAG_PRESENTATION, so flags alone are
     * not enough: the generic internal displays share the same localized name
     * ("内置屏幕"), while the HDMI output has its own one.
     */
    private fun isDeX(): Boolean = try {
        val displays = displayManager.displays
        if (displays == null) false else {
            val defaultName = displayManager.getDisplay(Display.DEFAULT_DISPLAY)?.name
            var found = -1
            for (d in displays) {
                if (d.displayId != Display.DEFAULT_DISPLAY &&
                    d.state == Display.STATE_ON &&
                    (d.flags and Display.FLAG_PRESENTATION) != 0 &&
                    (defaultName == null || d.name != defaultName)
                ) {
                    found = d.displayId
                    break
                }
            }
            dexDisplayId = found
            val dex = found >= 0
            if (debugLogs) {
                val sb = StringBuilder()
                for (d in displays) {
                    sb.append('[').append(d.displayId).append(' ').append(d.name)
                        .append(" state=").append(d.state)
                        .append(" flags=").append(d.flags)
                        .append(']')
                }
                Log.i(TAG, "displays: $sb dex=$dex")
                debugLogs = false
            }
            dex
        }
    } catch (t: Throwable) {
        false
    }

    private fun refreshDeX() {
        debugLogs = true
        val dex = isDeX()
        EngineState.dexConnected = dex
        if (prefs.autoDex && prefs.enabled) applyDesiredMode()
        updateNotification()
    }
}
