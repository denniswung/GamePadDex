package com.dennis.dexpad

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
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
    private var wakeLock: android.os.PowerManager.WakeLock? = null
    /** silent audio keeps Samsung Freecess from freezing the mapping process */
    private var silentTrack: android.media.AudioTrack? = null
    private val handler = Handler(Looper.getMainLooper())
    /** dedicated high-priority thread for the 8 ms mapping loop */
    private var engineThread: HandlerThread? = null
    private var engineHandler: Handler? = null
    private val axes = FloatArray(40)

    private var modeOn = false
    private var wheelAcc = 0f
    private var wheelHold = 0
    private var lastWheelHoldAt = 0L
    /** buttons whose wheel scroll is currently running (first key wins) */
    private val wheelButtons = mutableSetOf<String>()
    private var ticks = 0L
    private var lastSpawnAt = 0L
    private var debugLogs = true
    /** DeX / phone display bookkeeping (which screen to inject into) */
    private val displayState by lazy { DisplayState(this) }

    /** executes mapped one-shot actions through the root helper */
    private val actions by lazy {
        ActionRouter(object : ActionRouter.ActionHost {
            override fun root() = this@EngineService.root
            override fun prefs() = this@EngineService.prefs
            override fun displayState() = this@EngineService.displayState
            override fun display() = activeDisplay()
            override fun isPhone() = onPhone()
            override fun onArrowKey() = markNativeNav()
            override fun swipe(vertical: Boolean, dir: Int, slow: Boolean) = doSwipe(vertical, dir, slow)
            override fun lockArrowsFor(ms: Long) {
                arrowLockUntil = SystemClock.elapsedRealtime() + ms
            }

            /** 一次性居中：用引擎自己维护的指针位置，算一条相对位移，
             *  不再"先回角再跳"，因此不会有可见跳变，也不会把指针甩出屏幕。 */
            override fun centerPointer() {
                val (vw, vh) = displaySize(activeDisplay())
                if (ptrX.isNaN()) { ptrX = vw / 2f; ptrY = vh / 2f }
                val gain = prefs.centerGain
                val dx = (vw / 2f - ptrX) / gain
                val dy = (vh / 2f - ptrY) / gain
                if (Math.abs(dx) >= 0.5f || Math.abs(dy) >= 0.5f) root.move(dx, dy)
                ptrX = vw / 2f
                ptrY = vh / 2f
                Log.i(TAG, "center pointer dx=${dx.toInt()} dy=${dy.toInt()} gain=$gain -> ${vw / 2},${vh / 2}")
            }

            override fun launchApp(pkg: String) = launchTargetApp(pkg)

            override fun onCentered() {
                val (vw, vh) = displaySize(activeDisplay())
                ptrX = vw / 2f
                ptrY = vh / 2f
                lastUserInputAt = SystemClock.elapsedRealtime()
            }

            override fun onPointerNeeded() {
                lastUserInputAt = SystemClock.elapsedRealtime()
                showPointer()
            }

            override fun lockCenterFor(ms: Long) {
        ptrX = Float.NaN
        ptrY = Float.NaN
        euroX = OneEuroFilter()
        euroY = OneEuroFilter()
                centerLock = true
                centerLockUntil = SystemClock.elapsedRealtime() + ms
            }
        })
    }
    /** helper forwards the physical d-pad to a virtual gamepad (native mode) */
    /** 按下后会被摇杆运动吞掉自身单击动作的键（慢速指针修饰键） */
    private val STICK_MODIFIERS = setOf("x")
    private var dpadNative = false
    /** the system owns navigation right now (d-pad native), A = DPAD_CENTER */
    private var nativeNav = false
    /** native navigation expires quickly: A must be a click again right after */
    private var navUntil = 0L
    /** stick values at the moment native navigation started (baseline) */
    private var navBaseLx = 0f
    private var navBaseLy = 0f
    private var navBaseRx = 0f
    private var navBaseRy = 0f
    /** forwarding state was pushed to the current helper instance */
    private var dpadSent = false
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
    /** vertical touch-drag scrolling (stick up/down -> one drag per push) */
    private var vSwipeArmed = true
    private var vSwipeCooldownUntil = 0L
    /** LT/RT zoom: -1 out, +1 in, 0 idle; repeated while held */
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
    private val DOUBLE_WINDOW = 400L
    /** press order for combo leader detection (通用 §5.3) */
    private val pressAt = HashMap<String, Long>()
    private val longTimers = HashMap<String, Runnable>()
    private val longFired = HashSet<String>()
    /** estimated pointer position for edge slowdown (reset on L3 centre) */
    private var ptrX = Float.NaN
    private var ptrY = Float.NaN
    private var euroX = OneEuroFilter()
    private var euroY = OneEuroFilter()

    /** One Euro filter (通用 §4.2): low jitter at slow speed, low lag at speed */
    private class OneEuroFilter(
        var minCutoff: Double = 1.0,
        var beta: Double = 0.007,
        var dCutoff: Double = 1.0,
    ) {
        private var xPrev = 0.0
        private var dxPrev = 0.0
        private var first = true

        private fun alpha(cutoff: Double, dt: Double): Double {
            val tau = 1.0 / (2.0 * Math.PI * cutoff)
            return 1.0 / (1.0 + tau / dt)
        }

        /** 摇杆回中时调用：丢弃历史，避免残留速度继续推指针（松手滑行） */
        fun reset() {
            xPrev = 0.0
            dxPrev = 0.0
            first = true
        }

        fun filter(x: Double, dt: Double): Double {
            if (first) { first = false; xPrev = x; return x }
            val d = (x - xPrev) / dt
            val ad = alpha(dCutoff, dt)
            val dxHat = ad * d + (1 - ad) * dxPrev
            val cutoff = minCutoff + beta * Math.abs(dxHat)
            val a = alpha(cutoff, dt)
            val xHat = a * x + (1 - a) * xPrev
            xPrev = xHat
            dxPrev = dxHat
            return xHat
        }
    }

    // --- v1.45 key state machine: GUIDE help / X+GUIDE force stop / SELECT+START ---
    private var guideDownAt = 0L
    private var guideHelpShown = false
    private var guideHelpRunnable: Runnable? = null
    private var forceRunnable: Runnable? = null
    private var forceArmed = false
    /** X+GUIDE 已经触发过强杀：GUIDE 松开时不要再补一次短按动作 */
    private var forceFired = false
    private var screenRunnable: Runnable? = null
    private var screenArmed = false
    /** continuous mix output (X+volume, X+LB/RB): start after 300 ms, repeat 100-150 ms */
    private var mixHoldAction = ""
    private var mixHoldKeys: List<String> = emptyList()
    private var mixHoldStartAt = 0L
    private var mixHoldNextAt = 0L
    private var lastPtrLogAt = 0L
    /** uinput REL 单位 → 屏幕像素 的实测增益（指针加速之后约 2.16） */
    private val RAW_TO_PX = 2.16f
    /** 系统指针是否已被我们隐藏（销毁虚拟鼠标 = 没有指针设备 = 指针消失） */
    private var pointerHidden = false
    /** 当前 A 键按下走的是"触摸点击"（而不是鼠标左键） */
    private var leftIsTouch = false
    private var zooming = false
    /** d-pad 长按连发 */
    private var dpadRepeatRunnable: Runnable? = null
    private var dpadRepeatName: String? = null
    /** 最近一次下发给助手的触摸面尺寸 */
    private var touchSizeSent = ""
    /** 最近一次用户操作时间（摇杆/按键/点击），用于空闲自动隐藏 */
    private var lastUserInputAt = 0L

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        when (key) {
            Prefs.KEY_ENABLED -> {
                applyDesiredMode()
            }
            else -> {
            }
        }
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
        EngineBridge.service = this
        super.onCreate()
        EngineState.serviceRunning = true
        prefs = Prefs(this)
        createChannel()
        goForeground()
        // Samsung Freecess freezes cached-looking apps even with a specialUse FGS;
        // mediaPlayback + a partial wake lock keeps the mapping loop alive
        try {
            wakeLock = (getSystemService(Context.POWER_SERVICE) as android.os.PowerManager)
                .newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "dexpad:engine")
                .apply {
                    setReferenceCounted(false)
                    acquire()
                }
        } catch (t: Throwable) {
            Log.w(TAG, "wake lock failed: ${'$'}{t.message}")
        }
        startSilentAudio()
        try {
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
        Log.i(TAG, "engine started, socket=$SOCKET_PATH")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
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

    /** 隐藏系统指针：销毁虚拟鼠标设备（没有鼠标设备时系统不画指针） */
    private fun hidePointer() {
        if (pointerHidden || !root.helperReady) return
        root.raw("h")
        pointerHidden = true
        Log.i(TAG, "pointer hidden (mouse device destroyed)")
    }

    /** 恢复指针：重建虚拟鼠标 */
    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false
        Log.i(TAG, "pointer shown (mouse device recreated)")
    }

    /** 调试/测试用：把一条原始命令转发给 root 助手 */
    fun sendCmd(cmd: String): Boolean = runCatching { root.raw(cmd); true }.getOrDefault(false)

    override fun onDestroy() {
        if (EngineBridge.service === this) EngineBridge.service = null
        Log.i(TAG, "engine stopping")
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        try {
            silentTrack?.stop()
            silentTrack?.release()
        } catch (_: Throwable) {
        }
        silentTrack = null
        handler.removeCallbacks(tick)
        try {
            prefs.shared.unregisterOnSharedPreferenceChangeListener(prefsListener)
        } catch (_: Throwable) {
        }
        try {
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
                startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION_ID, n)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "startForeground failed: ${t.message}")
        }
    }

    /**
     * Samsung Freecess freezes 'cached' processes even when they run a foreground
     * service; apps with active audio playback are exempt, so keep a silent,
     * zero-volume stream running while the engine lives.
     */
    private fun startSilentAudio() {
        try {
            val rate = 48000
            val samples = ShortArray(4800)
            val track = android.media.AudioTrack.Builder()
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_MEDIA)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    android.media.AudioFormat.Builder()
                        .setEncoding(android.media.AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(rate)
                        .setChannelMask(android.media.AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(samples.size * 2)
                .setTransferMode(android.media.AudioTrack.MODE_STREAM)
                .build()
            track.setVolume(0f)
            track.play()
            silentTrack = track
            Thread({
                try {
                    while (track.playState == android.media.AudioTrack.PLAYSTATE_PLAYING) {
                        track.write(samples, 0, samples.size)
                    }
                } catch (_: Throwable) {
                }
            }, "dexpad-silent-audio").apply { isDaemon = true }.start()
            Log.i(TAG, "silent audio started (Freecess exemption)")
        } catch (t: Throwable) {
            Log.w(TAG, "silent audio failed: ${'$'}{t.message}")
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

    override fun onAxis(rawAxis: Int, value: Float) {
        // role swap (通用文档 §4.1): exchange the two sticks
        val axis = if (prefs.roleSwap) when (rawAxis) {
            0 -> 12
            1 -> 13
            12 -> 0
            13 -> 1
            else -> rawAxis
        } else rawAxis
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
        val name = KeyMap.buttonName(keyCode) ?: return
        val stamp = EngineState.lastEventMs
        handleButton(name, action == 0)
        // helper read -> action dispatched (both clocks are CLOCK_MONOTONIC)
        if (stamp > 0) EngineState.latAdd(System.nanoTime() / 1_000_000 - stamp)
    }

    /** common path for key-based and axis-based (dpad/trigger) buttons */
    private fun handleButton(name: String, down: Boolean) {
        // axis-derived buttons can report the same state twice (GAS+BRAKE pads),
        // and key events could repeat: only act on real transitions
        val wasDown = pressedButtons.contains(name)
        if (down == wasDown) return
        if (down) pressedButtons.add(name) else pressedButtons.remove(name)
        if (down) pressAt[name] = SystemClock.elapsedRealtime() else pressAt.remove(name)
        if (!down) cancelLong(name)

        if (handleSpecial(name, down)) return

        if (down) {
            Log.i(TAG, "button $name down mapped=${prefs.action(name)} mode=$modeOn ready=${root.helperReady}")
            // mouse mode off: only the SHARE toggle may act, everything else
            // belongs to the system while the controller is ungrabbed
            if (!modeOn && prefs.action(name) != Action.TOGGLE) return
            // wheel scroll: immediate, continuous until release; may also be
            // used as the *second* key of a chord (X+LB), never as its leader
            val mappedNow = prefs.action(name)
            if (isWheelAction(mappedNow)) {
                if (!fireMix()) {
                    startWheel(name, mappedNow)
                } else {
                    mixConsumed.add(name)
                }
                return
            }
            // a button with a double-press action delays its single action by
            // the double window; a second press inside the window fires the
            // double action and cancels the single
            val lng = prefs.longAction(name)
            if (lng != Action.NONE) scheduleLong(name, lng)
            val dbl = prefs.doubleAction(name)
            if (dbl != Action.NONE) {
                val pending = pendingDowns.remove(name)
                val now = SystemClock.elapsedRealtime()
                val last = lastDownAt[name] ?: 0L
                if (pending != null && now - last <= DOUBLE_WINDOW) {
                    cancelLong(name)
                    handler.removeCallbacks(pending)
                    lastDownAt[name] = 0L
                    Log.i(TAG, "double $name -> $dbl")
                    if (modeOn && root.helperReady) {
                        actions.fire(dbl, dblValue(name, dbl))
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
            if (lng != Action.NONE) {
                // wait for either the long-press timer or the release
                deferredSingles[name] = mappedNow
                return
            }
            processDown(name)
        } else {
            cancelDpadRepeat(name)
            stopWheel(name)
            releaseMixFor(name)
            val consumed = mixConsumed.remove(name)
            val wasLong = longFired.remove(name)
            if (wasLong) {
                pendingHolds.remove(name)?.let { handler.removeCallbacks(it) }
                deferredSingles.remove(name)
            }
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

    private fun handleSpecial(name: String, down: Boolean): Boolean {
        if (name == "guide") {
            if (down) {
                guideDownAt = SystemClock.elapsedRealtime()
                guideHelpShown = false
                if (pressedButtons.contains("x")) startForceTimer() else startGuideHelpTimer()
            } else {
                val consumedByCombo = forceFired
                cancelGuideHelp()
                cancelForce()
                if (guideHelpShown) {
                    guideHelpShown = false
                    Log.i(TAG, "guide help closed")
                } else if (!consumedByCombo && modeOn && root.helperReady) {
                    // 短按 GUIDE = 执行它的映射动作（默认"杀前台应用"）
                    val mapped = prefs.action("guide")
                    if (mapped != Action.NONE) {
                        Log.i(TAG, "guide short press -> $mapped")
                        actions.fire(mapped, valueFor("guide", mapped))
                    }
                }
                forceFired = false
                guideDownAt = 0L
            }
            return true
        }
        if (name == "x" && guideDownAt != 0L) {
            if (down) {
                if (!guideHelpShown) {
                    cancelGuideHelp()
                    startForceTimer()
                }
            } else {
                cancelForce()
            }
            return true
        }
        if (name == "select" || name == "start") {
            if (down) {
                val other = if (name == "select") "start" else "select"
                if (pressedButtons.contains(other)) {
                    startScreenTimer()
                    return true
                }
                if (name == "start" && screenArmed) return true
            } else {
                if (screenArmed) {
                    cancelScreenTimer()
                    return true
                }
            }
        }
        return false
    }

    private fun startGuideHelpTimer() {
        cancelGuideHelp()
        val r = Runnable {
            guideHelpRunnable = null
            if (pressedButtons.contains("guide") && !pressedButtons.contains("x")) {
                guideHelpShown = true
                Log.i(TAG, "guide help")
                showHelpToast()
                vibrate(40)
            }
        }
        guideHelpRunnable = r
        handler.postDelayed(r, 800L)
    }

    private fun cancelGuideHelp() {
        guideHelpRunnable?.let { handler.removeCallbacks(it) }
        guideHelpRunnable = null
    }

    private fun startForceTimer() {
        cancelForce()
        cancelGuideHelp()
        forceArmed = true
        val r = Runnable {
            forceRunnable = null
            if (forceArmed && pressedButtons.contains("x") && pressedButtons.contains("guide")) {
                forceArmed = false
                forceFired = true
                Log.i(TAG, "force stop by X+GUIDE")
                actions.fire(Action.FORCE_STOP, "")
                vibrate(120)
                toast("已强制停止当前应用")
            }
        }
        forceRunnable = r
        handler.postDelayed(r, 1500L)
        Log.i(TAG, "force timer armed")
    }

    private fun cancelForce() {
        forceArmed = false
        forceRunnable?.let { handler.removeCallbacks(it) }
        forceRunnable = null
    }

    private fun startScreenTimer() {
        cancelScreenTimer()
        screenArmed = true
        val r = Runnable {
            screenRunnable = null
            if (screenArmed) {
                screenArmed = false
                Log.i(TAG, "select+start -> screen toggle")
                actions.fire(Action.POWER, "")
                vibrate(60)
                toast("屏幕开/关")
            }
        }
        screenRunnable = r
        handler.postDelayed(r, 1000L)
        Log.i(TAG, "select+start timer armed")
    }

    private fun cancelScreenTimer() {
        screenArmed = false
        screenRunnable?.let { handler.removeCallbacks(it) }
        screenRunnable = null
    }

    private fun showHelpToast() {
        val text = "手柄映射帮助\n" +
            "A 左键/焦点  B 返回  X 修饰  Y Home\n" +
            "LB 上滑  RB 下滑  LT/RT 缩放\n" +
            "L3 居中  R3 静音/双击播放  SELECT 通知栏\n" +
            "START 上个应用  SHARE 鼠标模式\n" +
            "X+方向 音量/切歌  X+LB/RB 横滑\n" +
            "X+GUIDE 1.5s 强停  SELECT+START 1s 开关屏"
        try {
            android.widget.Toast.makeText(this, text, android.widget.Toast.LENGTH_LONG).show()
        } catch (_: Throwable) {
        }
    }

    private fun toast(text: String) {
        try {
            android.widget.Toast.makeText(this, text, android.widget.Toast.LENGTH_SHORT).show()
        } catch (_: Throwable) {
        }
    }

    private fun vibrate(ms: Long) {
        try {
            val v = getSystemService(VIBRATOR_SERVICE) as android.os.Vibrator
            if (android.os.Build.VERSION.SDK_INT >= 26) {
                v.vibrate(android.os.VibrationEffect.createOneShot(ms, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION") v.vibrate(ms)
            }
        } catch (_: Throwable) {
        }
    }

    /** repeat interval of the hold-scroll wheel (speed 1..10) */
    private fun wheelIntervalMs(): Long = (240L - prefs.wheelSpeed * 18L).coerceIn(50L, 240L)

    /** wheel steps per repeat (speed 1..10) */
    private fun wheelStep(): Int = (1 + (prefs.wheelSpeed - 1) / 3).coerceIn(1, 5)

    private fun isWheelAction(mapped: String): Boolean =
        mapped == Action.WHEEL_UP || mapped == Action.WHEEL_DOWN ||
            mapped == Action.WHEEL_LEFT || mapped == Action.WHEEL_RIGHT ||
            isScrollSwipeAction(mapped)

    private fun isScrollSwipeAction(mapped: String): Boolean =
        mapped == Action.SCROLL_SWIPE_UP || mapped == Action.SCROLL_SWIPE_DOWN ||
            mapped == Action.SCROLL_SWIPE_LEFT || mapped == Action.SCROLL_SWIPE_RIGHT

    /**
     * Start a wheel scroll the moment the key goes down and keep it running
     * until the key is released (the step() loop repeats it). This is why a
     * wheel button never waits for the double-press window or a mix grace.
     */
    private fun startWheel(name: String, mapped: String) {
        if (!modeOn || !root.helperReady) return
        wheelButtons.add(name)
        when (mapped) {
            // swipe-then-scroll: the short quick swipe starts a scrollable
            // surface that a plain wheel event cannot move on its own
            // finger up = content moves up (scroll down): the wheel must keep
            // scrolling the same way, so it is the opposite sign of the swipe
            Action.SCROLL_SWIPE_UP -> {
                doSwipe(true, -1, slow = true)
                wheelHold = -1
                lastWheelHoldAt = 0L
            }
            Action.SCROLL_SWIPE_DOWN -> {
                doSwipe(true, 1, slow = true)
                wheelHold = 1
                lastWheelHoldAt = 0L
            }
            Action.SCROLL_SWIPE_LEFT -> {
                doSwipe(false, -1, slow = true)
                hScrollDir = -1
                lastHScrollBtnAt = 0L
            }
            Action.SCROLL_SWIPE_RIGHT -> {
                doSwipe(false, 1, slow = true)
                hScrollDir = 1
                lastHScrollBtnAt = 0L
            }
            Action.WHEEL_UP -> {
                wheelHold = 1
                lastWheelHoldAt = 0L
                root.wheel(wheelStep())
            }
            Action.WHEEL_DOWN -> {
                wheelHold = -1
                lastWheelHoldAt = 0L
                root.wheel(-wheelStep())
            }
            Action.WHEEL_LEFT -> {
                hScrollDir = 1
                lastHScrollBtnAt = 0L
                doSwipe(false, 1, slow = true)
            }
            Action.WHEEL_RIGHT -> {
                hScrollDir = -1
                lastHScrollBtnAt = 0L
                doSwipe(false, -1, slow = true)
            }
        }
        Log.i(TAG, "wheel $mapped started by $name")
    }

    private fun stopWheel(name: String) {
        if (!wheelButtons.remove(name)) return
        if (wheelButtons.isEmpty()) {
            wheelHold = 0
            hScrollDir = 0
        }
        Log.i(TAG, "wheel stopped by $name")
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
            prefs.modeOn = !modeOn
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
        // Only the *leader* of a chord (the first key in "x+up") delays its own
        // action: a key that is only ever a follower (up, down, lb, ...) must
        // react immediately when pressed on its own.
        if (isMixLeader(name)) {
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
    private fun scheduleLong(name: String, action: String) {
        cancelLong(name)
        val r = Runnable {
            longTimers.remove(name)
            if (!pressedButtons.contains(name)) return@Runnable
            if (mixConsumed.contains(name)) return@Runnable
            longFired.add(name)
            pendingDowns.remove(name)?.let { handler.removeCallbacks(it) }
            deferredSingles.remove(name)
            Log.i(TAG, "long $name -> $action")
            if (modeOn && root.helperReady) actions.fire(action, longValue(name, action))
            vibrate(30)
        }
        longTimers[name] = r
        handler.postDelayed(r, prefs.longMs())
    }

    private fun cancelLong(name: String) {
        longTimers.remove(name)?.let { handler.removeCallbacks(it) }
    }

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
                Log.i(TAG, "A release: nativeNav=$nativeNav navActive=${navActive()} leftIsTouch=$leftIsTouch")
                if (navActive()) {
                    // the press was translated into DPAD_CENTER, nothing to release
                    pressedMouse.remove(0)
                } else if (leftIsTouch) {
                    val (px, py) = pointerPos()
                    root.touch(px, py, false)
                    leftIsTouch = false
                    pressedMouse.remove(0)
                    Log.i(TAG, "left touch up at ${px.toInt()},${py.toInt()}")
                } else {
                    root.button(0, false)
                    pressedMouse.remove(0)
                }
            }
            Action.RIGHT -> {
                root.button(1, false)
                pressedMouse.remove(1)
            }
            Action.MIDDLE -> {
                root.button(2, false)
                pressedMouse.remove(2)
            }
            Action.ZOOM_IN, Action.ZOOM_OUT -> {
                if (zooming) {
                    root.pinch(0, 0f, 0f)
                    zooming = false
                    Log.i(TAG, "pinch zoom stop")
                }
            }
            Action.WHEEL_UP, Action.WHEEL_DOWN -> wheelHold = 0
            Action.WHEEL_LEFT, Action.WHEEL_RIGHT -> hScrollDir = 0
            else -> {
            }
        }
    }

    /** 每个映射槽的参数：KEY_COMBO = 快捷键，OPEN_APP = 目标包名 */
    private fun valueFor(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.param(name)
        else -> prefs.combo(name)
    }

    private fun dblValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.paramDbl(name)
        Action.KEY_COMBO -> prefs.combo(name)
        else -> ""
    }

    private fun longValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefs.paramLng(name)
        Action.KEY_COMBO -> prefs.combo(name)
        else -> ""
    }

    /** d-pad 按住连发（键盘式）：400 ms 后每 110 ms 一次 */
    private fun startDpadRepeat(name: String, mapped: String) {
        if (!navActive()) return
        cancelDpadRepeat()
        dpadRepeatName = name
        val r = object : Runnable {
            override fun run() {
                if (dpadRepeatName != name || !pressedButtons.contains(name)) return
                if (!modeOn || !root.helperReady) return
                actions.fire(mapped, "")
                handler.postDelayed(this, 110L)
            }
        }
        dpadRepeatRunnable = r
        handler.postDelayed(r, 400L)
    }

    private fun cancelDpadRepeat(name: String? = null) {
        if (name != null && dpadRepeatName != name) return
        dpadRepeatRunnable?.let { handler.removeCallbacks(it) }
        dpadRepeatRunnable = null
        dpadRepeatName = null
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
                Log.i(TAG, "A pressed: nativeNav=$nativeNav navActive=${navActive()} leftTouch=${prefs.leftClickTouch}")
                if (navActive()) {
                    // native d-pad navigation: A activates the focused control
                    // instead of clicking at the (untouched) cursor position
                    root.pointKey(activeDisplay(), KeyEvent.KEYCODE_DPAD_CENTER)
                    Log.i(TAG, "A -> DPAD_CENTER (native nav)")
                } else if (prefs.leftClickTouch) {
                    // 可选：在光标位置注入真实触摸（只给"只认触摸"的 App 用）
                    val (px, py) = pointerPos()
                    showPointer()
                    root.touch(px, py, true)
                    leftIsTouch = true
                    pressedMouse.add(0)
                    Log.i(TAG, "left touch down at ${px.toInt()},${py.toInt()}")
                } else {
                    // 默认：鼠标左键事件——系统按真实光标位置处理，永远点得中
                    showPointer()
                    root.button(0, true)
                    leftIsTouch = false
                    pressedMouse.add(0)
                    Log.i(TAG, "left button down")
                }
            }
            Action.RIGHT -> {
                root.button(1, true)
                pressedMouse.add(1)
            }
            Action.MIDDLE -> {
                root.button(2, true)
                pressedMouse.add(2)
            }
            Action.ZOOM_IN, Action.ZOOM_OUT -> {
                if (navActive()) {
                    actions.fire(mapped, "")
                } else {
                    val (px, py) = pointerPos()
                    root.pinch(if (mapped == Action.ZOOM_IN) 1 else -1, px, py)
                    zooming = true
                    Log.i(TAG, "pinch zoom ${if (mapped == Action.ZOOM_IN) "in" else "out"} at ${px.toInt()},${py.toInt()}")
                }
            }
            Action.WHEEL_UP -> wheelHold = 1
            Action.WHEEL_DOWN -> wheelHold = -1
            // 手指方向 = 动作名字：向左滚动 = 手指往左（内容向左翻）
            Action.WHEEL_LEFT -> hScrollDir = -1
            Action.WHEEL_RIGHT -> hScrollDir = 1
            else -> actions.fire(mapped, valueFor(name, mapped))
        }
        if (mapped.startsWith("arrow_")) startDpadRepeat(name, mapped)
        if (!isOneShot(mapped) && mapped != Action.TOGGLE) startedHolds.add(name)
    }

    /** true when a mix slot with an action was completed by the current press */
    private fun fireMix(): Boolean {
        // 通用 §5.3: resolve by the actual first-pressed key (leader). Direct
        // configuration wins; a chord configured only in the opposite order is
        // inherited (equivalent key set), so X+A and A+X stay independent.
        fun leaderOf(keys: List<String>): String =
            keys.minByOrNull { pressAt[it] ?: Long.MAX_VALUE } ?: keys.first()

        for (pass in 0..1) {
            for (i in 0 until Prefs.MIX_COUNT) {
                if (mixFired[i]) continue
                val keys = prefs.mixKeys(i)
                if (keys.size < 2) continue
                val action = prefs.mixAction(i)
                if (action == Action.NONE) continue
                if (keys.any { !pressedButtons.contains(it) }) continue
                if (keys.any { wheelButtons.contains(it) }) continue
                // 卡住的按键（比如误触后没弹起的 L3）不能把单键动作劫持成组合：
                // 除发起键之外的每个键，都必须是 1.5s 内刚按下的。
                val nowMix = SystemClock.elapsedRealtime()
                val leaderNow = leaderOf(keys)
                val fresh = keys.filter { it != leaderNow }.all { k ->
                    val at = pressAt[k] ?: return@all false
                    nowMix - at <= 1500L
                }
                if (!fresh) continue
                val leader = leaderNow
                val direct = keys.first() == leader
                if (pass == 0 && !direct) continue     // direct pass
                if (pass == 1 && direct) continue      // inherited pass
                mixFired[i] = true
                for (k in keys) {
                    pendingHolds.remove(k)?.let { handler.removeCallbacks(it) }
                    deferredSingles.remove(k)
                    mixConsumed.add(k)
                    if (startedHolds.remove(k)) {
                        releaseActions(k, prefs.action(k))
                    }
                }
                Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action (${if (direct) "direct" else "inherited"})")
                fireMixAction(action, prefs.mixValue(i))
                armMixRepeat(action, keys)
                return true
            }
        }
        return false
    }

    /** 丢弃所有“按住”状态（断线/重连/卡键自愈时调用） */
    private fun clearPressedState(reason: String) {
        if (pressedButtons.isNotEmpty() || pressedMouse.isNotEmpty()) {
            Log.i(TAG, "clear pressed state ($reason): ${pressedButtons.joinToString(",")}")
        }
        pressedButtons.clear()
        pressAt.clear()
        mixConsumed.clear()
        deferredSingles.clear()
        pendingDowns.keys.toList().forEach { handler.removeCallbacks(pendingDowns.getValue(it) ?: return@forEach) }
        pendingDowns.clear()
        longFired.clear()
        for (i in 0 until Prefs.MIX_COUNT) mixFired[i] = false
        stopMixRepeat()
    }

    private fun releaseMixFor(name: String) {
        for (i in 0 until Prefs.MIX_COUNT) {
            if (mixFired[i] && prefs.mixKeys(i).contains(name)) mixFired[i] = false
        }
        if (mixHoldAction.isNotEmpty() && mixHoldKeys.contains(name)) stopMixRepeat()
    }

    /** X+volume and X+LB/RB: first pulse now, then repeat after 300 ms */
    private fun armMixRepeat(action: String, keys: List<String>) {
        val repeat = action == Action.VOLUME_UP || action == Action.VOLUME_DOWN ||
            action == Action.WHEEL_LEFT || action == Action.WHEEL_RIGHT
        if (!repeat) return
        mixHoldAction = action
        mixHoldKeys = keys
        val now = SystemClock.elapsedRealtime()
        mixHoldStartAt = now + 300L
        mixHoldNextAt = mixHoldStartAt
    }

    private fun stopMixRepeat() {
        mixHoldAction = ""
        mixHoldKeys = emptyList()
    }

    private fun mixRepeatIntervalMs(): Long =
        if (mixHoldAction == Action.WHEEL_LEFT || mixHoldAction == Action.WHEEL_RIGHT) 120L else 100L

    private fun repeatMixHold() {
        when (mixHoldAction) {
            Action.VOLUME_UP -> actions.fire(Action.VOLUME_UP, "")
            Action.VOLUME_DOWN -> actions.fire(Action.VOLUME_DOWN, "")
            Action.WHEEL_LEFT -> fireSwipeOnce(-1, 60)
            Action.WHEEL_RIGHT -> fireSwipeOnce(1, 60)
        }
    }

    /** true when [name] is the first key of at least one usable chord */
    private fun isMixLeader(name: String): Boolean {
        for (i in 0 until Prefs.MIX_COUNT) {
            val keys = prefs.mixKeys(i)
            if (keys.size >= 2 && prefs.mixAction(i) != Action.NONE && keys.first() == name) return true
        }
        return false
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
            Action.WHEEL_LEFT -> fireSwipeOnce(-1, 60)
            Action.WHEEL_RIGHT -> fireSwipeOnce(1, 60)
            Action.TOGGLE -> {
                // persist the user's switch: a supervisor restart must not undo it
                prefs.modeOn = !modeOn
                setMode(!modeOn)
            }
            else -> actions.fire(action, comboValue)
        }
    }

    /** releases everything we may be holding (mouse button / wheel hold / axis state) */
    private fun releaseHeld() {
        // 触摸点击模式下可能有一个触点还按着（断链/关模式/掉线时），必须抬起，
        // 否则那块屏幕区域会一直"被按住"。
        if (leftIsTouch) {
            val (px, py) = pointerPos()
            root.touch(px, py, false)
            leftIsTouch = false
        }
        if (zooming) {
            root.pinch(0, 0f, 0f)
            zooming = false
        }
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
        cancelDpadRepeat()
        mixConsumed.clear()
        mixFired.fill(false)
        dpadX = 0f
        dpadY = 0f
        ltDown = false
        rtDown = false
        wheelHold = 0
        hScrollDir = 0
        wheelButtons.clear()
        hSwipeArmed = true
        vSwipeArmed = true
    }

    private fun setMode(on: Boolean, force: Boolean = false) {
        if (!on) hidePointer() else showPointer()
        if (!force && modeOn == on) return
        modeOn = on
        EngineState.modeOn = on
        if (!on) {
            nativeNav = false
            releaseHeld()
        }
        if (root.helperReady) {
            if (on) {
                root.grab()
                // re-send the desired d-pad forwarding after re-grabbing
                dpadSent = false
            } else {
                root.ungrab()
                // no forwarding while the system owns the controller
                root.passthrough(false)
                dpadSent = true
            }
        }
        updateNotification()
        Log.i(TAG, "mouse mode " + if (on) "ON" else "OFF")
    }

    /** true when the engine should own the controller right now */
    private fun desiredMode(): Boolean =
        prefs.enabled && prefs.modeOn

    /** the display actions are injected into: DeX screen when present, otherwise the phone */
    private fun activeDisplay(): Int = displayState.active()


    override fun onPadKey(key: Int) {
        Log.i(TAG, "pad key $key (native nav)")
        markNativeNav()
    }

    /**
     * Enter native navigation: A now activates the focused control instead of
     * clicking at the cursor. Triggered both by the helper forwarding the d-pad
     * (`PAD`) and by arrow keys the app injects itself, so it works even when
     * d-pad forwarding is off (remapped direction, stale helper, ...).
     */
    /** true while A should activate the focused control instead of clicking */
    /** 光标当前位置（引擎跟踪值），用于触摸点击 / 双指缩放的基准点 */
    private fun pointerPos(): Pair<Float, Float> {
        val (vw, vh) = displaySize(activeDisplay())
        val cx = if (ptrX.isNaN()) vw / 2f else ptrX
        val cy = if (ptrY.isNaN()) vh / 2f else ptrY
        return Pair(
            cx.coerceIn(0f, vw.toFloat()),
            cy.coerceIn(0f, vh.toFloat()),
        )
    }

    /** 把触摸面尺寸同步给助手（旋转/分辨率变化时重发） */
    private fun syncTouchSize() {
        if (!root.helperReady) return
        val (vw, vh) = displaySize(activeDisplay())
        val key = "${vw}x$vh"
        if (key != touchSizeSent) {
            touchSizeSent = key
            root.touchSize(vw, vh)
        }
    }

    /** "打开目标应用"动作 */
    fun launchTargetApp(pkg: String) {
        try {
            val i = packageManager.getLaunchIntentForPackage(pkg)
            if (i == null) {
                Log.w(TAG, "open app: no launch intent for $pkg")
                toast("找不到应用 $pkg")
                return
            }
            i.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            // 后台服务直接 startActivity 会被系统拦截：优先让 root 助手 am start
            if (root.helperReady) root.openApp(pkg)
            else startActivity(i)
        } catch (t: Throwable) {
            Log.w(TAG, "open app failed: ${t.message}")
        }
    }

    // d-pad 导航模式：进入后一直有效，直到移动摇杆（想用鼠标）或关闭鼠标模式。
    // 不再用 1.2 秒超时——"d-pad 选中完再按 A 确认"是人的正常节奏，几秒钟很常见。
    private fun navActive(): Boolean = nativeNav

    private fun markNativeNav() {
        // 新的 d-pad 按下 = 明确要用方向键导航（刷新一次时间戳仅用于日志/兼容）
        if (!nativeNav) {
            // baseline: only a *change* of the stick leaves native navigation,
            // a stick that was already deflected must not switch out at once
            navBaseLx = axes[0]
            navBaseLy = axes[1]
            navBaseRx = axes[12]
            navBaseRy = axes[13]
            Log.i(TAG, "native navigation (d-pad)")
        }
        nativeNav = true
        navUntil = SystemClock.elapsedRealtime() + prefs.focusWindowMs()
        Log.i(TAG, "A 确认模式：d-pad 导航中（移动左摇杆回到鼠标点击）")
    }

    /** actions are going to the phone itself (no DeX display in use) */
    private fun onPhone(): Boolean = true

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
        // the helper pings every 2 s; silence means the socket died (helper or
        // client session restarted) -> drop it and reconnect
        if (ticks % 500 == 250L && root.helperReady &&
            SystemClock.elapsedRealtime() - root.lastLineAt > 6000
        ) {
            Log.w(TAG, "helper link silent, reconnecting")
            root.restart()
            return
        }
        // keep the mode in sync with the persisted switch (a crash or a
        // settings change must not leave the engine in the wrong state)
        if (ticks % 250 == 0L) applyDesiredMode()
        if (ticks % 125 == 0L && root.helperReady) root.queryTop()
        if (ticks % 250 == 0L) syncTouchSize()
        // 空闲自动隐藏指针：一段时间没有任何操作就销毁虚拟鼠标（系统就没指针可画），
        // 下次摇杆/按键操作时自动重建。
        run {
            val idleSec = prefs.idleHideSec
            if (idleSec > 0 && modeOn && root.helperReady && pressedButtons.isEmpty()) {
                val nowIdle = SystemClock.elapsedRealtime()
                if (lastUserInputAt == 0L) lastUserInputAt = nowIdle
                if (!pointerHidden && nowIdle - lastUserInputAt > idleSec * 1000L) hidePointer()
            }
        }
        if (ticks % 625 == 0L) {
            Log.i(TAG, "hb ready=${root.helperReady} silent=${SystemClock.elapsedRealtime() - root.lastLineAt}ms")
            val n = EngineState.latCount
            if (n > 0) {
                Log.i(TAG, "lat n=$n avg=${EngineState.latSum / n}ms max=${EngineState.latMax}ms")
                EngineState.latReset()
            }
            val caps = EngineState.caps
            if (caps.isNotEmpty()) {
                val bad = caps.filter { it.value == 0 }.keys
                if (bad.isNotEmpty()) Log.w(TAG, "cap missing: ${bad.joinToString(",")}")
            }
        }
        if (!root.helperReady) return
        // d-pad 导航模式只由摇杆移动退出（时间到不再自动退出）
        if (nativeNav && modeOn) {
            val dead = prefs.deadzone / 1000f
            val sd = prefs.scrollDeadzone / 1000f
            val dl = Math.hypot((axes[0] - navBaseLx).toDouble(), (axes[1] - navBaseLy).toDouble()).toFloat()
            val dr = maxOf(Math.abs(axes[12] - navBaseRx), Math.abs(axes[13] - navBaseRy))
            if (dl > dead || dr > sd) {
                nativeNav = false
                Log.i(TAG, "native navigation OFF (stick moved)")
            }
        }
        // d-pad 统一走 App（软件在虚拟控制器层之上）：助手不再自己原生转发，
        // 普通方向键与 X+方向键 只是 App 里的两种分支，互不抢占。
        if (!modeOn) {
            wheelHold = 0
            hScrollDir = 0
            wheelButtons.clear()
            hSwipeArmed = true
            vSwipeArmed = true
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
        // 卡键自愈：真实按键不会按住 15s 以上，超时就当它丢了 up 事件
        if (pressedButtons.isNotEmpty()) {
            val nowStale = SystemClock.elapsedRealtime()
            val stale = pressedButtons.filter { nowStale - (pressAt[it] ?: nowStale) > 15_000L }
            for (k in stale) {
                Log.i(TAG, "stale key dropped: $k (held >15s)")
                pressedButtons.remove(k)
                pressAt.remove(k)
                mixConsumed.remove(k)
                deferredSingles.remove(k)
                longFired.remove(k)
                for (i in 0 until Prefs.MIX_COUNT) if (prefs.mixKeys(i).contains(k)) mixFired[i] = false
            }
        }
        if (mixHoldAction.isNotEmpty()) {
            val nowMix = SystemClock.elapsedRealtime()
            if (nowMix >= mixHoldStartAt && nowMix >= mixHoldNextAt) {
                mixHoldNextAt = nowMix + mixRepeatIntervalMs()
                repeatMixHold()
            }
        }
        if (pendingDowns.containsKey("r3")) {
            val sd = prefs.scrollDeadzone / 1000f
            if (Math.abs(axes[12]) > sd || Math.abs(axes[13]) > sd) {
                pendingDowns.remove("r3")?.let { handler.removeCallbacks(it) }
                lastDownAt["r3"] = 0L
                Log.i(TAG, "double r3 cancelled (right stick moved)")
            }
        }
        val dead = prefs.deadzone / 1000f
        if (Math.abs(axes[0]) > dead || Math.abs(axes[1]) > dead ||
            Math.abs(axes[12]) > dead || Math.abs(axes[13]) > dead
        ) {
            lastUserInputAt = SystemClock.elapsedRealtime()
            showPointer()
        }
        val dtSec = (dtScale * 16f / 1000f).toDouble()
        var dx = curve(axes[0] * prefs.sensX(), dead)
        var dy = curve(axes[1] * prefs.sensY(), dead)
        if (dx == 0f && dy == 0f) {
            // 摇杆在死区内：立刻清零，不要用滤波器的衰减尾巴继续推指针，
            // 否则松手后指针还会滑出去一段（用户可直接感知的“太滑”）。
            euroX.reset()
            euroY.reset()
        } else {
            // One Euro: smooths the slow stick, keeps fast flicks responsive
            dx = euroX.filter(dx.toDouble(), dtSec).toFloat()
            dy = euroY.filter(dy.toDouble(), dtSec).toFloat()
        }
        if (dx != 0f || dy != 0f) {
            // X + left stick = precision mode: much slower pointer for aiming
            val precision = pressedButtons.contains("x")
            var scale = if (precision) prefs.precisionScale / 100f else 1f
            // edge slowdown (通用 §4.2): estimated pointer position, re-synced by L3
            val (vw, vh) = displaySize(activeDisplay())
            if (ptrX.isNaN()) { ptrX = vw / 2f; ptrY = vh / 2f }
            val margin = 0.08f
            val nx = (ptrX / vw.toFloat()).coerceIn(0f, 1f)
            val ny = (ptrY / vh.toFloat()).coerceIn(0f, 1f)
            if (prefs.edgeSlow() > 0 &&
                (nx < margin || nx > 1 - margin || ny < margin || ny > 1 - margin)
            ) {
                scale *= 1f - prefs.edgeSlow() / 100f
            }
            val speed = prefs.speedPhone * scale
            if (SystemClock.elapsedRealtime() >= arrowLockUntil) {
                val mx = dx * speed * dtScale
                val my = dy * speed * dtScale
                // 亚像素抖动不发：1px 的残余移动在慢速下会被看成“滑”
                if (Math.abs(mx) < 0.6f && Math.abs(my) < 0.6f) return
                // 按"引擎跟踪到的位置"把这一帧的位移夹在屏幕内：系统不会把注入的
                // REL 位移夹回屏幕，一旦推出去，光标就再也不出现（点击全部落空）。
                val gNow = prefs.centerGain
                val rx = mx.coerceIn((0f - ptrX) / gNow, (vw - ptrX) / gNow)
                val ry = my.coerceIn((0f - ptrY) / gNow, (vh - ptrY) / gNow)
                if (Math.abs(rx) < 0.01f && Math.abs(ry) < 0.01f) return
                root.move(rx, ry)
                // sampled trail: lets the tests verify sensitivity without
                // reading the system pointer position
                val nowPtr = SystemClock.elapsedRealtime()
                if (nowPtr - lastPtrLogAt > 300) {
                    lastPtrLogAt = nowPtr
                    Log.i(TAG, "ptr move dx=${rx.toInt()} dy=${ry.toInt()} at ${ptrX.toInt()},${ptrY.toInt()}")
                }
                ptrX = (ptrX + rx * gNow).coerceIn(0f, vw.toFloat())
                ptrY = (ptrY + ry * gNow).coerceIn(0f, vh.toFloat())
            }
        }

        // right stick -> wheel. A dedicated, larger dead zone (scroll_deadzone)
        // and a remap of [dead..1] to [0..1] keep a drifting or lightly touched
        // stick from scrolling, while still allowing fine slow scrolling.
        val scrollDead = prefs.scrollDeadzone / 1000f
        var sy = axes[13]                       // AXIS_RY
        if (Math.abs(sy) < 0.02f) sy = axes[14] // AXIS_RZ (pads without RX/RY)
        val ny = scrollCurve(sy, scrollDead)
        // 控件级焦点: keep the scrollable-control rectangle fresh while the
        // right stick is scrolling (the helper dumps at most every 5 s)
        if (prefs.vTouchScroll) {
            // a real finger drag: ViewPager-style feeds (short-video pages)
            // only snap to a page after a drag; wheel steps leave them stuck
            // halfway between two pages
            if (ny != 0f) {
                val now = SystemClock.elapsedRealtime()
                // holding the stick keeps paging: one drag every swipeRepeatMs
                if (now >= vSwipeCooldownUntil) {
                    vSwipeArmed = false
                    val display = activeDisplay()
                    val (w, h) = displaySize(display)
                    // app-agnostic gesture policy: pull down = one shade pull
                    // from the top edge; push up = one long slow drag repeated
                    // back-to-back so the content keeps moving
                    // 摇杆向上 = 想看上面的内容 = 手指向下拖（内容跟手指往下走）；
                    // 摇杆向下 = 手指向上拖。起点用 30% / 65%，不要用 3%：
                    // 从顶部手势区起手会被系统当成「拉通知栏」，页面完全不动。
                    val up = ny < 0
                    val dist = (h * (if (up) 0.35f else 0.30f)).toInt().coerceIn(320, 1100)
                    val pct = if (up) 30 else 65
                    val dy = if (up) dist else -dist
                    val ms = if (up) 220 else 380
                    val (cxp, cyp) = pointerPos()
                    root.swipeV(display, dy, ms, w, h, pct, cxp.toInt(), cyp.toInt())
                    vSwipeCooldownUntil = now + ms + 30L
                    if (debugLogs) Log.i(TAG, "vswipe $dy on display $display")
                }
            } else if (SystemClock.elapsedRealtime() >= vSwipeCooldownUntil) {
                vSwipeArmed = true
            }
        } else if (ny != 0f) {
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

        // 只有「摇杆修饰键」才允许被摇杆运动取消单键动作：
        // X 按住 + 左摇杆 = 慢速指针（设计如此），它按下时不该再触发左键；
        // 其它组合发起键（Y）不能因为摇杆有位移就丢掉自己的单击动作，
        // 否则「点进应用后马上按 Y 回主屏」会因摇杆残留/微动而完全没反应。
        if (deferredSingles.isNotEmpty() &&
            (dx != 0f || dy != 0f || ny != 0f || nx != 0f)
        ) {
            for (k in deferredSingles.keys.toList()) {
                if (k !in STICK_MODIFIERS) continue
                if (mixConsumed.add(k)) {
                    Log.i(TAG, "single deferred for $k cancelled (stick used while held)")
                }
            }
            if ("x" in STICK_MODIFIERS) {
                pendingDowns.remove("x")?.let { handler.removeCallbacks(it) }
                lastDownAt["x"] = 0L
            }
        }
        if (nx != 0f) {
            val nowH = SystemClock.elapsedRealtime()
            if (nowH >= swipeCooldownUntil) {
                hSwipeArmed = false
                swipeStep(if (nx > 0) -1 else 1)
                swipeCooldownUntil = nowH + hSwipeRepeatMs()
            }
        } else if (SystemClock.elapsedRealtime() >= swipeCooldownUntil) {
            hSwipeArmed = true
        }
        if (hScrollDir != 0) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastHScrollBtnAt >= wheelIntervalMs() * 3 / 2) {
                lastHScrollBtnAt = now
                doSwipe(false, hScrollDir, slow = true)
            }
        }

        if (wheelHold != 0) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastWheelHoldAt >= wheelIntervalMs()) {
                lastWheelHoldAt = now
                root.wheel(wheelHold)
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
    /**
     * Unified touch swipe (one geometry for every caller: right stick,
     * swipe actions, mix slots). vertical: dir > 0 = finger down.
     */
    /** 前台是不是桌面（桌面没有可滚动内容，下滑手势会被它当成「拉通知栏」） */
    private fun launcherForeground(): Boolean {
        val p = EngineState.topPackage.lowercase()
        // 桌面、系统弹窗（ResolverActivity 之类）、SystemUI 都没有可滚动内容，
        // 在这些界面上发触摸滑动只会触发系统手势，改成方向键更安全。
        return p.contains("launcher") || p.endsWith(".home") || p.contains("flauncher") ||
            p == "android" || p.contains("systemui")
    }

    private fun doSwipe(vertical: Boolean, dir: Int, slow: Boolean = false, widthPct: Int = 0) {
        if (dir == 0) return
        val now = SystemClock.elapsedRealtime()
        if (now < swipeCooldownUntil) return
        // 桌面：没有可滚内容，滑动只会触发系统手势（下滑拉出状态栏）。
        // 交回上层虚拟控制器：发方向键，让系统自己做焦点导航。
        if (launcherForeground()) {
            val arrow = when {
                vertical && dir > 0 -> Action.ARROW_DOWN
                vertical -> Action.ARROW_UP
                dir > 0 -> Action.ARROW_RIGHT
                else -> Action.ARROW_LEFT
            }
            actions.fire(arrow, "")
            swipeCooldownUntil = now + 160
            Log.i(TAG, "launcher foreground -> arrow instead of $dir swipe")
            return
        }
        val display = activeDisplay()
        val (w, h) = displaySize(display)
        // the SLOW_* actions are short quick flicks: fast, but long enough to
        // actually trigger a system gesture (Lawnchair's app drawer needs about
        // a quarter of the screen; a 12% nudge just springs back)
        val ms = if (slow) 120 else 200
        if (vertical) {
            val dist = if (slow) (h * 0.25f).toInt().coerceIn(320, 900)
            else (h * 0.5f).toInt().coerceIn(420, 1800)
            // -1 = 以光标为锚点（在任务内时），助手只在光标不可用时退回任务中心
            val (cxp, cyp) = pointerPos()
            root.swipeV(display, if (dir > 0) dist else -dist, ms, w, h, -1, cxp.toInt(), cyp.toInt())
        } else {
            val dist = if (widthPct > 0) (w * widthPct / 100f).toInt().coerceIn(400, 1600)
            else if (slow) (w * 0.25f).toInt().coerceIn(320, 900)
            else (w * 0.4f).toInt().coerceIn(500, 1200)
            val (cxp, cyp) = pointerPos()
            root.swipeH(display, dir * dist, ms, w, h, -1, cxp.toInt(), cyp.toInt())
        }
        swipeCooldownUntil = now + ms + if (slow) 20 else 170
        if (debugLogs) Log.i(TAG, "swipe vertical=$vertical dir=$dir slow=$slow ms=$ms on display $display")
    }

    private fun swipeStep(dir: Int) = doSwipe(false, dir)

    /** repeat interval while the stick stays deflected (continuous paging) */
    private fun swipeRepeatMs(): Long =
        (620L - prefs.scrollSpeed * 30L).coerceIn(260L, 700L)

    /** 横向翻页节奏：受「水平滑动速度」控制（原来这个滑杆是无效的） */
    private fun hSwipeRepeatMs(): Long =
        (680L - prefs.hswipeSpeed * 40L).coerceIn(220L, 760L)

    private fun displaySize(id: Int): Pair<Int, Int> = displayState.size(id)

    /** one-shot horizontal swipe used by mix slots / wheel-left-right actions */
    private fun fireSwipeOnce(dir: Int, widthPct: Int = 0) = doSwipe(false, dir, false, widthPct)

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


    /** 手柄掉线：它的 up 事件永远不会来了，必须清状态，否则组合会卡在“已触发” */
    override fun onDeviceGone() {
        clearPressedState("device gone")
        releaseHeld()
    }

    override fun onReady() {
        // 链路自检: report missing root capabilities instead of failing silently
        root.selftest()
        // 助手重启后鼠标设备可能仍处于「被空闲隐藏」状态，触摸面尺寸也可能变了：
        // 两个状态都重置，保证第一下点击/缩放就正确
        pointerHidden = false
        touchSizeSent = ""
        root.raw("j")
        EngineState.connected = true
        EngineState.lastError = ""
        if (prefs.forceLandscape) root.setRotation(1)
        // a (re)started helper has forwarding off: force a re-send
        dpadSent = false
        // 助手重启后手柄可能已经断过一轮，之前按下的键不会再有 up 事件：
        // 不清掉会留下“幽灵按键”，把后续单键动作劫持成组合（例如 Y 变成电源）。
        clearPressedState("helper ready")
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
        pointerHidden = false
        touchSizeSent = ""
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
}
