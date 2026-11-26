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
    /** t22: LB/RB 按住滚动统一——按压开始时定下的机制（true=连续滑动，false=滚轮） */
    private var holdTouchMode = true
    /** 连续滑动模式：当前按住的竖向滑动方向（0=无，-1=上，+1=下） */
    private var swipeHold = 0
    private var lastSwipeHoldAt = 0L
    /** t26: 主/备锚点交替标志 */
    private var holdSwipeAlt = false
    /** t31: 触屏模式连续拖拽（helper d/m/e） */
    private var dragActive = false
    private var dragDir = 0
    private var dragX = 0
    private var dragAnchorY = 0
    private var dragDisplay = 0
    private var dragAccum = 0
    private var dragTotal = 0
    private var dragStartAt = 0L
    private var dragLastMoveAt = 0L
    /** 上一帧的位移量（px），用于限制加速度（每 16ms 增长 ≤0.8%，250ms 增量差 ≤~13%） */
    private var dragLastDy = 14f
    /** t36: 本次按压的 scroll_speed 倍率（按压开始时定下，按压中不切换） */
    private var dragMult = 1f
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
            override fun display() = geomId
            override fun isPhone() = onPhone()
            override fun onArrowKey() = markNativeNav()
            override fun swipe(vertical: Boolean, dir: Int, slow: Boolean) = doSwipe(vertical, dir, slow)
            override fun lockArrowsFor(ms: Long) {
                arrowLockUntil = SystemClock.elapsedRealtime() + ms
            }

            override fun launchApp(pkg: String) = launchTargetApp(pkg)

            override fun onPointerNeeded() {
                lastUserInputAt = SystemClock.elapsedRealtime()
                showPointer()
            }

            override fun lockCenterFor(ms: Long) {
                ptrX = Float.NaN
                ptrY = Float.NaN
                euroX.reset()
                euroY.reset()
                centerLock = true
                centerLockUntil = SystemClock.elapsedRealtime() + ms
            }

            override fun centerCursorClosedLoop() = this@EngineService.requestCenter()
        })
    }
    /** helper forwards the physical d-pad to a virtual gamepad (native mode) */
    /** 按下后会被摇杆运动吞掉自身单击动作的键（慢速指针修饰键） */
    private val STICK_MODIFIERS = setOf("x")
    private var dpadNative = false
    /** the system owns navigation right now (d-pad native), A = DPAD_CENTER */
    private var nativeNav = false
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
    /** one horizontal gesture is in flight until this timestamp */
    private var swipeCooldownUntil = 0L
    /** v1.69: 横向摇杆独立冷却——避免刚做过竖滑时把横向输入吞掉（SCR-022） */
    private var hSwipeCooldownUntil = 0L
    /** v1.69: 横向摇杆期间的被动光标同步（外部 P/真实指针位置可能与引擎估算不同） */
    private var hCursorSyncAt = 0L
    /** 垂直触摸滚动：一次手势在飞期间不再发第二条 */
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
    /** 隐藏时停车位（-1 = 未停车）与隐藏前的真实位置 */
    private var parkedAtX = -1f
    private var parkedAtY = 0f
    private var lastPosX = Float.NaN
    private var lastPosY = Float.NaN
    private var euroX = OneEuroFilter()
    private var euroY = OneEuroFilter()

    // ---------------------------------------------------------------- v1.66
    // 8 ms 循环里不再读 SharedPreferences / 不再查 DisplayManager：所有热路径参数
    // 由 prefs 变更监听器刷新到这组快照字段里。
    private val btnIdx = HashMap<String, Int>(32).apply {
        Prefs.BUTTONS.forEachIndexed { i, b -> put(b, i) }
    }
    private val cAction = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cLong = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cDouble = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cParam = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cParamDbl = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cParamLng = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cCombo = arrayOfNulls<String>(Prefs.BUTTONS.size)
    private val cMixKeys = Array(Prefs.MIX_COUNT) { emptyList<String>() }
    private val cMixAction = Array(Prefs.MIX_COUNT) { Action.NONE }
    private val cMixValue = Array(Prefs.MIX_COUNT) { "" }
    private var cEnabled = true
    private var cModeOnPref = true
    private var cDead = 0.16f
    private var cScrollDead = 0.35f
    private var cSensX = 1f
    private var cSensY = 1f
    private var cSpeedPhoneInt = 48
    private var cPrecision = 0.15f
    private var cEdgeSlow = 40
    private var cIdleHideSec = 8
    private var cScrollSpeed = 4
    private var cHswipeSpeed = 7
    private var cVTouch = true
    private var cInvertScroll = false
    private var cWheelSpeed = 3
    private var cCenterGain = 2.16f
    private var cForceLandscape = true
    private var cFocusWindowMs = 1200L
    private var cLongMs = 500L
    private var cLeftTouch = false
    private var cWakeStick = 800
    private var cWakeHoldMs = 200
    private var cWakeRiseMs = 120
    private var cRoleSwap = false
    /** 缓存快照代次：主线程写、引擎线程读，volatile 读写建立可见性 */
    @Volatile
    private var prefsGen = 0
    private var lastSeenPrefsGen = 0

    /** 当前注入的 display + 它的 app 尺寸/旋转（1 s 或显示变化时刷新） */
    private var geomId = 0
    private var geomW = 0
    private var geomH = 0
    private var geomRot = 0
    private var geomNextCheckAt = 0L
    /**
     * 物理指针空间映射（v1.66）：display_size_forced 覆盖 + 折叠屏会让系统把应用画面
     * 等比缩放并居中画在物理面板上（实测 app 2560x1600 → 面板 2316x904，scale 0.565、
     * offset 435,0）。助手/系统的指针坐标是物理空间，触摸/点击是应用空间。
     */
    private var physPanelW = 0
    private var physPanelH = 0
    private var physScale = 1f
    private var physOffX = 0f
    private var physOffY = 0f
    private var physAppW = 0f
    private var physAppH = 0f

    /** 实测 REL 单位 → 屏幕像素 增益（0 = 未标定，用 center_gain 当初始猜测） */
    @Volatile
    private var moveGain = 0f

    /** 真实光标位置追踪（助手 c/W 命令回包） */
    private var lastRealX = -1
    private var lastRealY = -1
    private var lastRealAt = 0L
    private var relAccX = 0.0
    private var relAccY = 0.0
    private var relClamped = false
    private var wasMovingPointer = false
    @Volatile
    private var cursorQueryInFlight = false
    @Volatile
    private var cursorQueryAt = 0L
    private var cursorLegacyRetry = false
    @Volatile
    private var cursorCmdModern = true
    @Volatile
    private var probeForCenter = false
    private var probeGainOk = true
    private var probeBaseX = -1
    private var probeBaseY = -1
    private var probeRelX = 0.0
    private var probeRelY = 0.0
    private var probeClamped = false

    /** L3 闭环居中状态机 */
    @Volatile
    private var centerActive = false
    private var centerIter = 0
    private var centerW = 0
    private var centerH = 0
    private var centerPrevX = -1
    private var centerPrevY = -1
    private var centerRelX = 0f
    private var centerRelY = 0f
    private var centerGainUsed = 0f
    private var centerRequestedAt = 0L
    private var centerPRequestedAt = 0L
    private var centerTargetX = 0f
    private var centerTargetY = 0f

    /** 摇杆唤醒（大幅快速推左摇杆 → 助手 u 命令点亮屏幕） */
    private var wakeArmed = true
    private var wakeStartAt = 0L
    private var wakeFast = false
    private var wakeHoldAt = 0L
    private var wakeLastAt = 0L
    /** 首次 m>=阈值 的时刻（用于 riseCrossMs ≤120ms 判据） */
    private var wakeRiseCrossAt = 0L
    private var wakeRiseLogged = false
    private var powerManager: android.os.PowerManager? = null

    /** 帧耗时统计（每 5 s 汇总一次） */
    private var perfTickN = 0
    private var perfTickSumUs = 0L
    private var perfTickMaxUs = 0L
    private var lastEdgeLogAt = 0L
    private var lastAxisArbLogAt = 0L
    private var lastRotGuardAt = 0L
    /** 空闲节流：无按键/摇杆/滚轮/居中时循环降到 16ms */
    private var idleLoop = false
    private var lastPtrSyncLogAt = 0L
    private var lastMoveSentAt = 0L
    private var lastStateModeOn = false

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
        // v1.66：任何一个参数变更都只刷新一次内存快照，8 ms 循环不再碰 SharedPreferences
        refreshCachedPrefs()
        when (key) {
            Prefs.KEY_ENABLED -> applyDesiredMode()
            else -> {}
        }
    }

    private val tick = object : Runnable {
        override fun run() {
            val t0 = System.nanoTime()
            try {
                step()
            } catch (t: Throwable) {
                Log.e(TAG, "tick failed", t)
            }
            val us = (System.nanoTime() - t0) / 1000L
            perfTickN++
            perfTickSumUs += us
            if (us > perfTickMaxUs) perfTickMaxUs = us
            // 空闲时 16ms 一拍（省电/降低 CPU），有按键/摇杆/滚轮/居中时恢复 8ms
            engineHandler?.postDelayed(this, if (idleLoop) 16L else 8L)
        }
    }

    override fun onCreate() {
        EngineBridge.service = this
        super.onCreate()
        EngineState.serviceRunning = true
        prefs = Prefs(this)
        refreshCachedPrefs()
        moveGain = prefs.moveGainCal
        powerManager = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
        refreshGeometry(force = true)
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
        Log.i(TAG, "engine started, socket=$SOCKET_PATH prefs=cached moveGain=$moveGain")
    }

    /**
     * 把 SharedPreferences 里所有热路径参数读进内存（v1.66 提速项）：
     * 以前每 8 ms tick 会做 10+ 次 prefs 查询，按键路径每次还会遍历 24 个组合位。
     */
    private fun refreshCachedPrefs() {
        try {
            cEnabled = prefs.enabled
            cModeOnPref = prefs.modeOn
            cDead = prefs.deadzone / 1000f
            cScrollDead = prefs.scrollDeadzone / 1000f
            cSensX = prefs.sensX()
            cSensY = prefs.sensY()
            cSpeedPhoneInt = prefs.speedPhone
            cPrecision = prefs.precisionScale / 100f
            cEdgeSlow = prefs.edgeSlow()
            cIdleHideSec = prefs.idleHideSec
            cScrollSpeed = prefs.scrollSpeed
            cHswipeSpeed = prefs.hswipeSpeed
            cVTouch = prefs.vTouchScroll
            cInvertScroll = prefs.invertScroll
            cWheelSpeed = prefs.wheelSpeed
            cCenterGain = prefs.centerGain
            cForceLandscape = prefs.forceLandscape
            cFocusWindowMs = prefs.focusWindowMs()
            cLongMs = prefs.longMs()
            cLeftTouch = prefs.leftClickTouch
            cWakeStick = prefs.wakeStick
            cWakeHoldMs = prefs.wakeHoldMs
            cWakeRiseMs = prefs.wakeRiseMs
            cRoleSwap = prefs.roleSwap
            for (i in 0 until Prefs.BUTTONS.size) {
                val b = Prefs.BUTTONS[i]
                cAction[i] = prefs.action(b)
                cLong[i] = prefs.longAction(b)
                cDouble[i] = prefs.doubleAction(b)
                cParam[i] = prefs.param(b)
                cParamDbl[i] = prefs.paramDbl(b)
                cParamLng[i] = prefs.paramLng(b)
                cCombo[i] = prefs.combo(b)
            }
            for (i in 0 until Prefs.MIX_COUNT) {
                cMixKeys[i] = prefs.mixKeys(i)
                cMixAction[i] = prefs.mixAction(i)
                cMixValue[i] = prefs.mixValue(i)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "prefs cache refresh failed: ${t.message}")
        }
        prefsGen++
    }

    private fun prefAction(name: String): String {
        val i = btnIdx[name] ?: return Action.NONE
        return cAction[i] ?: Action.NONE
    }

    private fun prefLong(name: String): String {
        val i = btnIdx[name] ?: return Action.NONE
        return cLong[i] ?: Action.NONE
    }

    private fun prefDouble(name: String): String {
        val i = btnIdx[name] ?: return Action.NONE
        return cDouble[i] ?: Action.NONE
    }

    private fun prefParam(name: String): String {
        val i = btnIdx[name] ?: return ""
        return cParam[i] ?: ""
    }

    private fun prefParamDbl(name: String): String {
        val i = btnIdx[name] ?: return ""
        return cParamDbl[i] ?: ""
    }

    private fun prefParamLng(name: String): String {
        val i = btnIdx[name] ?: return ""
        return cParamLng[i] ?: ""
    }

    private fun prefCombo(name: String): String {
        val i = btnIdx[name] ?: return Prefs.DEFAULT_COMBO
        return cCombo[i] ?: Prefs.DEFAULT_COMBO
    }

    private fun mixKeys(i: Int): List<String> = cMixKeys[i]

    private fun mixAction(i: Int): String = cMixAction[i]

    private fun mixValue(i: Int): String = cMixValue[i]

    /** 当前注入目标 display + 它的 app 尺寸/旋转；返回 true = 几何变了 */
    private fun refreshGeometry(force: Boolean = false): Boolean {
        val now = SystemClock.elapsedRealtime()
        if (!force && now < geomNextCheckAt) return false
        geomNextCheckAt = now + 1000L
        val id = displayState.active()
        val (w, h) = displayState.size(id)
        val rot = displayState.rotation(id)
        val (pw, ph) = displayState.physicalSize(id)
        if (id == geomId && w == geomW && h == geomH && rot == geomRot && pw == physPanelW && ph == physPanelH) return false
        val changed = geomW > 0 && (w != geomW || h != geomH || rot != geomRot || pw != physPanelW || ph != physPanelH)
        geomId = id
        geomW = w
        geomH = h
        geomRot = rot
        physPanelW = if (pw > 0) pw else w
        physPanelH = if (ph > 0) ph else h
        // v1.66：助手 c / P 统一使用「应用逻辑坐标」（display 0 的 getSize 空间）。
        // 之前尝试在 App 侧复算 Samsung 的 letterbox/旋转缩放，实测多显示下不可靠，
        // 已把坐标换算收口到助手（c 返回逻辑坐标）；这里保持恒等映射。
        physScale = 1f
        physOffX = 0f
        physOffY = 0f
        physAppW = w.toFloat()
        physAppH = h.toFloat()
        Log.i(
            TAG,
            "geometry app=${w}x$h rot=$rot panel=${physPanelW}x$physPanelH " +
                "scale=%.4f offset=%.1f,%.1f appPhys=%.0fx%.0f".format(physScale, physOffX, physOffY, physAppW, physAppH),
        )
        if (changed) {
            // 旋转/分辨率变了：估算坐标已不可信，等真实光标回包重新同步（不发任何修正移动）
            ptrX = Float.NaN
            ptrY = Float.NaN
            Log.i(TAG, "geometry changed -> ${w}x$h rot=$rot display=$id (estimate reset, no correction move)")
            engineHandler?.post { sendCursorQuery(SystemClock.elapsedRealtime(), false) }
        }
        return changed
    }

    // ---- 物理指针空间 <-> 应用(逻辑)坐标 换算 ----

    /** 物理指针坐标 → 应用坐标（触摸注入 / 手指滑动锚点要用应用坐标） */
    private fun physToLogical(x: Float, y: Float): Pair<Float, Float> {
        val s = if (physScale > 0f) physScale else 1f
        return Pair((x - physOffX) / s, (y - physOffY) / s)
    }

    private fun logicalToPhysX(x: Float): Float = physOffX + x * physScale

    private fun logicalToPhysY(y: Float): Float = physOffY + y * physScale

    /** 指针所在的应用区域（物理坐标）宽度/高度 */
    private fun physAppMaxX(): Float = physOffX + physAppW

    private fun physAppMaxY(): Float = physOffY + physAppH

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

    /** 隐藏指针：销毁虚拟鼠标设备（系统不画指针，瞬间消失） */
    private fun hidePointer() {
        if (pointerHidden || !root.helperReady) return
        root.raw("h")
        pointerHidden = true
        Log.i(TAG, "pointer hidden (device destroyed)")
    }

    /** 恢复指针：只重建设备。系统会保留光标坐标，所以光标直接出现在上次位置，
     *  没有任何可见的"修正移动"（这就是"隐形修正"）。 */
    private fun showPointer() {
        if (!pointerHidden || !root.helperReady) return
        root.raw("j")
        pointerHidden = false
        Log.i(TAG, "pointer shown at last position (no correction move)")
    }

    // ------------------------------------------- v1.66 真实光标 / 增益闭环居中

    private fun currentGain(): Float =
        if (moveGain >= 1.0f && moveGain <= 12.0f) moveGain else cCenterGain

    private fun updateMoveGain(g: Float, src: String) {
        if (g < 1.0f || g > 12.0f) return
        val old = moveGain
        if (old > 0f) {
            val ratio = g / old
            // 指针加速让增益随速度变化：被动采样（快速推杆）只允许小幅修正，
            // L3 直接测量（P 落点）允许更大修正，避免一次异常采样把增益带偏。
            val hi = if (src == "l3-initial") 3.0f else if (src == "passive") 1.25f else 1.6f
            val lo = 1f / hi
            if (ratio > hi || ratio < lo) {
                Log.i(TAG, "moveGain rejected $g (src=$src, current=$old ratio=%.2f)".format(ratio))
                return
            }
            if (Math.abs(g - old) / old < 0.02f) return
        }
        moveGain = g
        // 持久化：下次开机/助手重启后不用再标定一遍
        prefs.moveGainCal = g
        Log.i(TAG, "moveGain calibrated $old -> $g (src=$src center_gain=$cCenterGain)")
    }

    /** 两轴反推的增益取一个稳健值（过滤夹边/取整噪声） */
    private fun robustGain(gx: Double, gy: Double): Float {
        val x = if (gx >= 1.0 && gx <= 12.0) gx.toFloat() else -1f
        val y = if (gy >= 1.0 && gy <= 12.0) gy.toFloat() else -1f
        return when {
            x > 0f && y > 0f -> {
                val hi = maxOf(x, y)
                val lo = minOf(x, y)
                if (lo / hi >= 0.8f) (x + y) / 2f else hi
            }
            x > 0f -> x
            y > 0f -> y
            else -> -1f
        }
    }

    /**
     * 向助手要一次真实光标位置：新助手用 `c`（fork 子进程，不阻塞主循环），
     * 老助手（v1.65）只有 `W`，350 ms 内收不到回包就自动退回 `W`。
     * 只读位置，**从不移动光标**，所以空闲隐藏/恢复的"无修正移动"语义不变。
     */
    private fun sendCursorQuery(now: Long, forCenter: Boolean, allowGain: Boolean = true) {
        if (!root.helperReady) return
        if (cursorQueryInFlight) return
        cursorQueryInFlight = true
        cursorQueryAt = now
        probeForCenter = forCenter
        probeGainOk = allowGain
        probeBaseX = lastRealX
        probeBaseY = lastRealY
        probeRelX = relAccX
        probeRelY = relAccY
        probeClamped = relClamped
        if (cursorCmdModern) root.queryCursor() else root.queryCursorLegacy()
        if (cursorCmdModern) {
            val stamp = now
            engineHandler?.postDelayed({
                if (cursorQueryInFlight && cursorQueryAt == stamp) {
                    cursorCmdModern = false
                    cursorQueryInFlight = false
                    Log.i(TAG, "cursor command 'c' unsupported, fallback to legacy 'W'")
                    sendCursorQuery(SystemClock.elapsedRealtime(), forCenter)
                }
            }, 350L)
        }
    }

    override fun onCursor(x: Int, y: Int) {
        val now = SystemClock.elapsedRealtime()
        cursorQueryInFlight = false
        if (probeForCenter && now - centerRequestedAt < 240L) {
            // 助手 O 自身至少要跑 40 步（>240 ms）才有落点；更早的回包是上一次
            // 旧查询（被动同步）的迟到响应，不能拿它当居中反馈。
            Log.i(TAG, "CURSOR stale response ignored (before center O finished)")
            return
        }
        if (x < 0 || y < 0) {
            Log.i(TAG, "CURSOR unavailable (pointer hidden / no sprite)")
            if (probeForCenter) finishCenterNoFeedback()
            return
        }
        if (probeForCenter) handleCenterCursor(x, y, now) else handlePassiveCursor(x, y, now)
    }

    override fun onWake(line: String) {
        Log.i(TAG, "helper $line")
    }

    /** 被动标定：用"上次真实位置 + 之后发出的 REL 总量"反推增益，并同步估算位置 */
    private fun handlePassiveCursor(x: Int, y: Int, now: Long) {
        if (probeGainOk && probeBaseX >= 0 && probeBaseY >= 0 && !probeClamped) {
            val gx = if (Math.abs(probeRelX) >= 24.0) (x - probeBaseX) / probeRelX else -1.0
            val gy = if (Math.abs(probeRelY) >= 24.0) (y - probeBaseY) / probeRelY else -1.0
            val g = robustGain(gx, gy)
            if (g > 0f) updateMoveGain(g, "passive")
        }
        val ex = if (ptrX.isNaN()) -1 else ptrX.toInt()
        val ey = if (ptrY.isNaN()) -1 else ptrY.toInt()
        ptrX = x.toFloat()
        ptrY = y.toFloat()
        lastRealX = x
        lastRealY = y
        lastRealAt = now
        relAccX = 0.0
        relAccY = 0.0
        relClamped = false
        if (now - lastPtrSyncLogAt > 5000L) {
            lastPtrSyncLogAt = now
            Log.i(TAG, "ptr synced to real $x,$y (est was $ex,$ey) gain=$moveGain")
        }
    }

    /**
     * 居中闭环：助手 O 报出的落点反推真实增益 G（落点 = (中心/gainApplied)×G），
     * 与中心比较后只补一条相对位移；最多 3 次修正，不再靠"多等一会"。
     */
    private fun handleCenterCursor(x: Int, y: Int, now: Long) {
        centerIter++
        val tx = centerTargetX.toInt()
        val ty = centerTargetY.toInt()
        if (centerIter == 1) {
            // 助手 P：先有界推到 (0,0)（物理空间），再走一步 target/gain
            val gx = if (tx > 4) x.toDouble() * centerGainUsed / tx else -1.0
            val gy = if (ty > 4) y.toDouble() * centerGainUsed / ty else -1.0
            val g = robustGain(gx, gy)
            if (g > 0f) updateMoveGain(g, "l3-initial")
        } else if (centerPrevX >= 0 || centerPrevY >= 0) {
            val gx = if (Math.abs(centerRelX) >= 8f) (x - centerPrevX) / centerRelX.toDouble() else -1.0
            val gy = if (Math.abs(centerRelY) >= 8f) (y - centerPrevY) / centerRelY.toDouble() else -1.0
            val g = robustGain(gx, gy)
            if (g > 0f) updateMoveGain(g, "l3-correct")
        }
        val ex = tx - x
        val ey = ty - y
        val (lax, lay) = physToLogical(x.toFloat(), y.toFloat())
        Log.i(
            TAG,
            "L3 probe iter=$centerIter phys=$x,$y target=$tx,$ty errPhys=$ex,$ey " +
                "logical=${lax.toInt()},${lay.toInt()} gain=${currentGain()}",
        )
        if (Math.abs(ex) <= 8 && Math.abs(ey) <= 8) {
            finishCenter(x, y, now, "")
            return
        }
        if (centerIter >= 4) {
            finishCenter(x, y, now, " maxiter")
            return
        }
        val g = currentGain()
        centerRelX = ex / g
        centerRelY = ey / g
        centerPrevX = x
        centerPrevY = y
        root.move(centerRelX, centerRelY)
        relAccX += centerRelX
        relAccY += centerRelY
        lastMoveSentAt = now
        Log.i(TAG, "L3 correction iter=$centerIter rel=${centerRelX.toInt()},${centerRelY.toInt()} gain=$g")
        engineHandler?.postDelayed({
            if (centerActive) sendCursorQuery(SystemClock.elapsedRealtime(), true)
        }, 120L)
    }

    private fun finishCenter(x: Int, y: Int, now: Long, note: String) {
        centerActive = false
        ptrX = x.toFloat()
        ptrY = y.toFloat()
        lastRealX = x
        lastRealY = y
        lastRealAt = now
        relAccX = 0.0
        relAccY = 0.0
        relClamped = false
        val (lx, ly) = physToLogical(x.toFloat(), y.toFloat())
        val ex = lx - geomW / 2f
        val ey = ly - geomH / 2f
        Log.i(
            TAG,
            "CENTER_OK phys=$x,$y targetPhys=${centerTargetX.toInt()},${centerTargetY.toInt()} " +
                "logical=${lx.toInt()},${ly.toInt()} targetLogical=${geomW / 2},${geomH / 2} " +
                "err=${ex.toInt()},${ey.toInt()} gain=${currentGain()} iters=$centerIter moveGain=$moveGain " +
                "l3TookMs=${now - centerRequestedAt}$note",
        )
        lastUserInputAt = now
    }

    private fun finishCenterNoFeedback() {
        centerActive = false
        ptrX = centerTargetX
        ptrY = centerTargetY
        val (lx, ly) = physToLogical(centerTargetX, centerTargetY)
        Log.i(
            TAG,
            "CENTER_NOCURSOR targetLogical=${geomW / 2},${geomH / 2} targetPhys=${centerTargetX.toInt()},${centerTargetY.toInt()} " +
                "logical=${lx.toInt()},${ly.toInt()} gain=${currentGain()} l3TookMs=${SystemClock.elapsedRealtime() - centerRequestedAt} " +
                "(estimate only, no extra move)",
        )
    }

    /** L3：退出 d-pad 粘性导航 → 物理空间绝对定位到应用区域中心 → 真实落点闭环 */
    private fun requestCenter() {
        val now = SystemClock.elapsedRealtime()
        lastUserInputAt = now
        showPointer()
        if (nativeNav) {
            nativeNav = false
            Log.i(TAG, "L3 clears native navigation (A -> mouse click again)")
        }
        refreshGeometry(force = true)
        centerTargetX = physOffX + physAppW / 2f
        centerTargetY = physOffY + physAppH / 2f
        centerW = geomW
        centerH = geomH
        centerActive = true
        centerIter = 0
        centerPrevX = -1
        centerPrevY = -1
        centerGainUsed = currentGain()
        ptrX = Float.NaN
        ptrY = Float.NaN
        euroX.reset()
        euroY.reset()
        centerLock = true
        centerLockUntil = now + 1500L
        centerRequestedAt = now
        cursorQueryInFlight = false
        // 助手 P 用 raw→px 增益做绝对定位：先把当前标定增益写进去（g 0 <gain>）
        root.setGain(centerGainUsed)
        // 事件驱动：助手 P 完成会回 `POSPTR x,y`，收到后立刻发 c 校验；
        // 固定延时只作为兜底（P 内部有 40 步有界步进，正常 ~300–450ms）。
        centerPRequestedAt = now
        root.positionPointer(centerTargetX.toInt(), centerTargetY.toInt(), physPanelW, physPanelH)
        engineHandler?.postDelayed({
            if (centerActive && centerIter == 0 && !cursorQueryInFlight) {
                Log.i(TAG, "L3 fallback: no POSPTR after ${SystemClock.elapsedRealtime() - centerPRequestedAt}ms, query cursor")
                sendCursorQuery(SystemClock.elapsedRealtime(), true)
            }
        }, 700L)
        Log.i(
            TAG,
            "L3 center begin app=${geomW}x$geomH panel=${physPanelW}x$physPanelH " +
                "targetPhys=${centerTargetX.toInt()},${centerTargetY.toInt()} gainApplied=$centerGainUsed " +
                "moveGain=$moveGain navCleared=true",
        )
    }

    /** 助手 P（pointer_goto）完成的回包：立刻用它触发真实光标校验，替代固定 520ms 等待 */
    override fun onPositioned(x: Int, y: Int) {
        if (!centerActive || centerIter != 0) return
        val now = SystemClock.elapsedRealtime()
        Log.i(
            TAG,
            "L3 POSPTR x=$x y=$y after=${now - centerPRequestedAt}ms -> query cursor",
        )
        if (!cursorQueryInFlight) sendCursorQuery(now, true)
    }

    /**
     * 摇杆唤醒（新功能6）：灭屏时"大幅 + 快速 + 保持"推左摇杆 → 助手 `u` 点亮屏幕。
     * 小幅（<30% 或不到阈值）与慢推（上升到阈值 > wake_rise_ms）都不触发。
     */
    private fun checkWake(now: Long) {
        val m = Math.hypot(axes[0].toDouble(), axes[1].toDouble()).toFloat()
        val thr = cWakeStick / 1000f
        if (m < 0.30f) {
            wakeArmed = true
            wakeStartAt = 0L
            wakeFast = false
            wakeHoldAt = 0L
            wakeRiseCrossAt = 0L
            wakeRiseLogged = false
            return
        }
        if (wakeStartAt == 0L) {
            wakeStartAt = now
            wakeFast = m >= thr
            if (m >= thr) wakeRiseCrossAt = now
        }
        if (m >= thr && wakeRiseCrossAt == 0L) {
            // 单独记录「首次 m>=thr」的时间：riseCrossMs 才是 ≤120ms 的“快速”判据；
            // sinceStartMs 是包含 hold 的总耗时，不能拿来判快速。
            wakeRiseCrossAt = now
            val riseCrossMs = now - wakeStartAt
            val fastByRise = riseCrossMs <= cWakeRiseMs
            if (!wakeRiseLogged) {
                wakeRiseLogged = true
                Log.i(
                    TAG,
                    "wake riseCross: m=$m riseCrossMs=$riseCrossMs sinceStartMs=${now - wakeStartAt}ms " +
                        "fast=$fastByRise thr=$thr limit=${cWakeRiseMs}ms",
                )
            }
            if (fastByRise) wakeFast = true
        }
        if (m >= thr) {
            if (wakeHoldAt == 0L) wakeHoldAt = now
            if (wakeFast && wakeArmed && now - wakeHoldAt >= cWakeHoldMs && now - wakeLastAt >= 2500L) {
                wakeArmed = false
                wakeLastAt = now
                val interactive = try {
                    powerManager?.isInteractive ?: true
                } catch (_: Throwable) {
                    true
                }
                if (interactive) {
                    Log.i(TAG, "wake skip: screen interactive (m=$m)")
                } else {
                    root.wakeScreen()
                    Log.i(
                        TAG,
                        "wake sent: helper u (m=$m riseCrossMs=${wakeRiseCrossAt - wakeStartAt}ms " +
                            "sinceStartMs=${now - wakeStartAt}ms hold=${now - wakeHoldAt}ms thr=$thr)",
                    )
                }
            }
        }
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
        val axis = if (cRoleSwap) when (rawAxis) {
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
        // v1.66：任何一次按键都算"用户操作"。旧版只更新摇杆，于是空闲 8s 后按 A
        // 会先重建指针、点击刚发出就又被空闲隐藏销毁（首击丢点的根源之一）。
        lastUserInputAt = SystemClock.elapsedRealtime()
        if (down) pressedButtons.add(name) else pressedButtons.remove(name)
        if (down) pressAt[name] = SystemClock.elapsedRealtime() else pressAt.remove(name)
        if (!down) cancelLong(name)

        if (handleSpecial(name, down)) return

        if (down) {
            Log.i(TAG, "button $name down mapped=${prefAction(name)} mode=$modeOn ready=${root.helperReady}")
            // mouse mode off: only the SHARE toggle may act, everything else
            // belongs to the system while the controller is ungrabbed
            if (!modeOn && prefAction(name) != Action.TOGGLE) return
            // wheel scroll: immediate, continuous until release; may also be
            // used as the *second* key of a chord (X+LB), never as its leader
            val mappedNow = prefAction(name)
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
            val lng = prefLong(name)
            if (lng != Action.NONE) scheduleLong(name, lng)
            val dbl = prefDouble(name)
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
            val mapped = prefAction(name)
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
                    val mapped = prefAction("guide")
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
            "Y+↑ PiliPlus  Y+↓ 抖音\n" +
            "灭屏时大幅快速推左摇杆 = 亮屏\n" +
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
    private fun wheelIntervalMs(): Long = (240L - cWheelSpeed * 18L).coerceIn(50L, 240L)

    /** wheel steps per repeat (speed 1..10) */
    private fun wheelStep(): Int = (1 + (cWheelSpeed - 1) / 3).coerceIn(1, 5)

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
        // t22: 机制在按压开始时定下，按压期间不切换：
        // 触摸滚动开 -> 只用连续滑动；关 -> 只用滚轮。同一按压内绝不混用。
        holdTouchMode = cVTouch
        when (mapped) {
            // v1.66 的“先滑一次再滚”混合已删除：两种模式二选一
            Action.SCROLL_SWIPE_UP -> {
                if (holdTouchMode) {
                    startDrag(-1)
                } else {
                    ensureWheelAnchor()
                    wheelHold = -1
                    lastWheelHoldAt = 0L
                    root.wheel(-wheelStep())
                }
                Log.i(TAG, "hold-scroll $mapped by $name mode=${if (holdTouchMode) "swipe" else "wheel"}")
            }
            Action.SCROLL_SWIPE_DOWN -> {
                if (holdTouchMode) {
                    startDrag(1)
                } else {
                    ensureWheelAnchor()
                    wheelHold = 1
                    lastWheelHoldAt = 0L
                    root.wheel(wheelStep())
                }
                Log.i(TAG, "hold-scroll $mapped by $name mode=${if (holdTouchMode) "swipe" else "wheel"}")
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
            if (dragActive) endDrag(SystemClock.elapsedRealtime())
            wheelHold = 0
            swipeHold = 0
            hScrollDir = 0
        }
        Log.i(TAG, "wheel stopped by $name (mode=${if (holdTouchMode) "swipe" else "wheel"})")
    }

    /** t26: 滚轮模式按压开始前，确保指针可见且悬停在当前 task 中部（否则 REL_WHEEL 可能落在不可滚区域） */
    private fun ensureWheelAnchor() {
        val wasHidden = pointerHidden
        showPointer()
        val (lx, ly) = pointerPos()
        val cx = geomW / 2f
        val cy = geomH / 2f
        if (wasHidden || Math.abs(lx - cx) > 8f || Math.abs(ly - cy) > 8f) {
            root.positionPointer(
                (physOffX + physAppW / 2f).toInt(),
                (physOffY + physAppH / 2f).toInt(),
                physPanelW,
                physPanelH,
            )
            Log.i(TAG, "wheel anchor: pointer to task center (hidden=$wasHidden was=$lx,$ly)")
        } else {
            Log.i(TAG, "wheel anchor: pointer already at task center ($lx,$ly)")
        }
    }

    /** t26: 连续滑动锚点自适应——按 task 高度百分比取中部滚动区，主/备锚点交替（避开顶部手势区/底部导航区） */
    /** t31: 触屏模式 LB/RB 连续拖拽（helper d/m/e），速度模型 800→1500px/s，16ms/帧 */
    private fun dragSpeedAt(tMs: Float): Float = when {
        tMs < 400f -> 900f
        tMs < 1400f -> 900f + 600f * (tMs - 400f) / 1000f
        else -> 1500f
    }
    private fun startDrag(dir: Int) {
        if (!modeOn || !root.helperReady) return
        // t36: scroll_speed 1..10 → 拖拽速度整体倍率 0.6..1.8（默认 4 → 1.0，保持现手感）
        dragMult = (0.6f + (cScrollSpeed - 1) * (1.2f / 9f)).coerceIn(0.6f, 1.8f)
        dragDir = dir
        dragX = (geomW * 0.5f).toInt()
        // RB(finger-up) 从 60% 起手向上拖；LB(finger-down) 从 25% 起手向下拖
        // （LB 若从 40% 起手，页面滚到底时该点落入内层 ListView，拖拽被内层吞掉、外层 PY 不动）
        dragAnchorY = (geomH * (if (dir < 0) 0.60f else 0.25f)).toInt()
        dragDisplay = geomId
        dragAccum = 0
        dragTotal = 0
        dragLastDy = 900f * 0.016f * dragMult
        dragStartAt = SystemClock.elapsedRealtime()
        dragLastMoveAt = dragStartAt
        dragActive = true
        root.dragDown(dragDisplay, dragX, dragAnchorY)
        Log.i(
            TAG,
            "drag start dir=$dir anchor=($dragX,$dragAnchorY) scroll_speed=$cScrollSpeed mult=$dragMult " +
                "task=0..$geomH maxTotal=${(2200 * dragMult).toInt()}",
        )
    }

    private fun dragTick(now: Long) {
        if (!dragActive) return
        if (now - dragLastMoveAt < 16L) return
        val t = (now - dragStartAt).toFloat()
        val dt = ((now - dragLastMoveAt).coerceAtMost(20L)) / 1000f
        val capStep = dragSpeedAt(t) * dragMult * dt
        // 加速度限制：每帧最多增长 0.8%（16ms/帧 → 250ms 约 +12.7%），避免“一顿一顿”
        val grown = dragLastDy * 1.008f + 0.2f
        val dyAbs = minOf(capStep, grown).coerceAtLeast(1f)
        dragLastDy = dyAbs
        val dy = dyAbs.toInt().coerceAtLeast(1) * dragDir
        val margin = 80
        val avail = if (dragDir < 0) dragAnchorY - margin else (geomH - margin) - dragAnchorY
        if ((dragAccum + dy) > avail || (dragAccum + dy) < -avail) {
            // 接近 task 边界（≥80px 余量）：up 后在新锚点 down 续拖，内容偏移连续、无可见跳跃
            root.dragUp(dragDisplay)
            val newY = (geomH * (if (dragDir < 0) 0.60f else 0.25f)).toInt()
            dragAnchorY = newY
            dragAccum = 0
            root.dragDown(dragDisplay, dragX, newY)
            Log.i(TAG, "drag re-anchor y=$newY (margin=$margin, total=$dragTotal)")
        }
        root.dragMove(dragDisplay, 0, dy, 16)
        dragAccum += dy
        dragTotal += kotlin.math.abs(dy)
        dragLastMoveAt = now
        if (dragTotal >= (2200 * dragMult).toInt()) {
            endDrag(now)
            Log.i(TAG, "drag stop cap total=$dragTotal t=${now - dragStartAt}ms mult=$dragMult")
        }
    }

    private fun endDrag(now: Long) {
        if (!dragActive) return
        dragActive = false
        // 两帧零位移再抬起：清掉 Android 的 fling 速度，松手后不滑行（惯性 ≤200px）
        root.dragMove(dragDisplay, 0, 0, 16)
        root.dragMove(dragDisplay, 0, 0, 16)
        root.dragUp(dragDisplay)
        Log.i(TAG, "drag end total=${dragTotal}px dur=${now - dragStartAt}ms")
    }

    /** the action side of a button press (delayed by DOUBLE_WINDOW when the button has a double action) */
    private fun processDown(name: String) {
        if (fireMix()) return
        if (mixConsumed.contains(name)) {
            Log.i(TAG, "single for $name skipped (mix consumed)")
            return
        }
        val mapped = prefAction(name)
        if (mapped == Action.NONE) return
        if (mapped == Action.TOGGLE) {
            prefs.modeOn = !modeOn
            cModeOnPref = !modeOn
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
        handler.postDelayed(r, cLongMs)
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
        Action.OPEN_APP -> prefParam(name)
        else -> prefCombo(name)
    }

    private fun dblValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefParamDbl(name)
        Action.KEY_COMBO -> prefCombo(name)
        else -> ""
    }

    private fun longValue(name: String, mapped: String): String = when (mapped) {
        Action.OPEN_APP -> prefParamLng(name)
        Action.KEY_COMBO -> prefCombo(name)
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
                Log.i(TAG, "A pressed: nativeNav=$nativeNav navActive=${navActive()} leftTouch=$cLeftTouch")
                if (navActive()) {
                    // native d-pad navigation: A activates the focused control
                    // instead of clicking at the (untouched) cursor position
                    root.pointKey(geomId, KeyEvent.KEYCODE_DPAD_CENTER)
                    Log.i(TAG, "A -> DPAD_CENTER (native nav)")
                } else if (cLeftTouch) {
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
                val keys = mixKeys(i)
                if (keys.size < 2) continue
                val action = mixAction(i)
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
                        releaseActions(k, prefAction(k))
                    }
                }
                Log.i(TAG, "mix $i ${keys.joinToString("+")} -> $action (${if (direct) "direct" else "inherited"})")
                fireMixAction(action, mixValue(i))
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
            if (mixFired[i] && mixKeys(i).contains(name)) mixFired[i] = false
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
            val keys = mixKeys(i)
            if (keys.size >= 2 && mixAction(i) != Action.NONE && keys.first() == name) return true
        }
        return false
    }

    private fun inAnyMix(name: String): Boolean {
        for (i in 0 until Prefs.MIX_COUNT) {
            val keys = mixKeys(i)
            if (keys.size >= 2 && mixAction(i) != Action.NONE && keys.contains(name)) return true
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
                cModeOnPref = !modeOn
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
        if (dragActive) endDrag(SystemClock.elapsedRealtime())
        wheelHold = 0
        swipeHold = 0
        hScrollDir = 0
        wheelButtons.clear()
        vSwipeCooldownUntil = 0L
        hSwipeCooldownUntil = 0L
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
    private fun desiredMode(): Boolean = cEnabled && cModeOnPref

    /** the display actions are injected into: the built-in screen that is on */
    private fun activeDisplay(): Int = geomId


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
    /** 光标当前位置（引擎跟踪值，物理空间）→ 应用坐标，用于触摸点击 / 双指缩放 / 滑动锚点 */
    private fun pointerPos(): Pair<Float, Float> {
        val vw = geomW
        val vh = geomH
        val px = if (ptrX.isNaN()) physOffX + physAppW / 2f else ptrX
        val py = if (ptrY.isNaN()) physOffY + physAppH / 2f else ptrY
        val (lx, ly) = physToLogical(px, py)
        return Pair(
            lx.coerceIn(0f, vw.toFloat()),
            ly.coerceIn(0f, vh.toFloat()),
        )
    }

    /** 把触摸面尺寸同步给助手（旋转/分辨率变化时重发） */
    private fun syncTouchSize() {
        if (!root.helperReady) return
        val vw = geomW
        val vh = geomH
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
        Log.i(TAG, "A 确认模式：d-pad 导航中（移动左摇杆回到鼠标点击）")
    }

    /** actions are going to the phone itself (no DeX display in use) */
    private fun onPhone(): Boolean = true

    private fun applyDesiredMode() {
        val want = desiredMode()
        if (want != modeOn) setMode(want, force = !want)
    }

    private fun step() {
        ticks++
        if (prefsGen != lastSeenPrefsGen) lastSeenPrefsGen = prefsGen
        // the loop runs every 8 ms; speeds are expressed per 16 ms frame, so
        // scale by the real elapsed time to keep the pointer speed unchanged
        val nowMs = SystemClock.elapsedRealtime()
        val dtScale = if (lastTickAt == 0L) 0.5f
        else ((nowMs - lastTickAt).coerceIn(1L, 64L).toFloat() / 16f).coerceIn(0.1f, 4f)
        lastTickAt = nowMs
        // 空闲节流判定（不影响按键：按键走 link 线程；也不影响推杆：有轴输入即恢复 8ms）
        idleLoop = pressedButtons.isEmpty() && wheelHold == 0 && mixHoldAction.isEmpty() &&
            !centerActive && !centerLock &&
            Math.abs(axes[0]) <= cDead && Math.abs(axes[1]) <= cDead &&
            Math.abs(axes[12]) <= cScrollDead && Math.abs(axes[13]) <= cScrollDead &&
            (lastUserInputAt == 0L || nowMs - lastUserInputAt > 1000L)
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
        if (ticks % 250 == 0L) {
            syncTouchSize()
            refreshGeometry()
        }
        // v1.66 横屏守护（t8）：force_landscape 以前只在 helper ready 写一次 rotation=1，
        // 外部/三星把 user_rotation 改成 0 或重新打开 accelerometer_rotation 后就停在竖屏。
        // 这里每秒复核一次，不符就重新下发 r 1（助手会同时关掉 accelerometer_rotation）。
        if (ticks % 125 == 0L && root.helperReady && cForceLandscape && geomRot != 1 &&
            nowMs - lastRotGuardAt > 1500L
        ) {
            lastRotGuardAt = nowMs
            root.setRotation(1)
            geomNextCheckAt = 0L
            Log.i(TAG, "landscape guardian: rotation $geomRot -> 1 (force_landscape=true)")
        }
        // 空闲自动隐藏指针：一段时间没有任何操作就销毁虚拟鼠标（系统就没指针可画），
        // 下次摇杆/按键操作时自动重建。（每 32 ms 检查一次即可，省掉每 tick 的比较）
        if (ticks % 4 == 0L) {
            val idleSec = cIdleHideSec
            if (idleSec > 0 && modeOn && root.helperReady && pressedButtons.isEmpty()) {
                if (lastUserInputAt == 0L) lastUserInputAt = nowMs
                if (!pointerHidden && nowMs - lastUserInputAt > idleSec * 1000L) hidePointer()
            }
        }
        if (ticks % 625 == 0L) {
            Log.i(TAG, "hb ready=${root.helperReady} silent=${SystemClock.elapsedRealtime() - root.lastLineAt}ms")
            val n = EngineState.latCount
            if (n > 0) {
                Log.i(TAG, "lat n=$n avg=${EngineState.latSum / n}ms max=${EngineState.latMax}ms")
                EngineState.latReset()
            }
            if (perfTickN > 0) {
                Log.i(
                    TAG,
                    "perf tick n=$perfTickN avg=${perfTickSumUs / perfTickN}us max=${perfTickMaxUs}us " +
                        "prefs_per_tick=0 gain=$moveGain",
                )
                perfTickN = 0
                perfTickSumUs = 0L
                perfTickMaxUs = 0L
            }
            val caps = EngineState.caps
            if (caps.isNotEmpty()) {
                val bad = caps.filter { it.value == 0 }.keys
                if (bad.isNotEmpty()) Log.w(TAG, "cap missing: ${bad.joinToString(",")}")
            }
        }
        if (!root.helperReady) return
        if (lastStateModeOn != modeOn) {
            lastStateModeOn = modeOn
            EngineState.modeOn = modeOn
        }
        // d-pad 导航模式只由摇杆移动退出（时间到不再自动退出）
        if (nativeNav && modeOn) {
            val dl = Math.hypot((axes[0] - navBaseLx).toDouble(), (axes[1] - navBaseLy).toDouble()).toFloat()
            val dr = maxOf(Math.abs(axes[12] - navBaseRx), Math.abs(axes[13] - navBaseRy))
            if (dl > cDead || dr > cScrollDead) {
                nativeNav = false
                Log.i(TAG, "native navigation OFF (stick moved)")
            }
        }
        // d-pad 统一走 App（软件在虚拟控制器层之上）：助手不再自己原生转发，
        // 普通方向键与 X+方向键 只是 App 里的两种分支，互不抢占。
        if (!modeOn) {
            if (dragActive) endDrag(SystemClock.elapsedRealtime())
            wheelHold = 0
            swipeHold = 0
            hScrollDir = 0
            wheelButtons.clear()
            wakeArmed = true
            wakeStartAt = 0L
            wakeFast = false
            wakeHoldAt = 0L
            return
        }
        // 摇杆唤醒（灭屏时大幅+快速+保持才触发；小幅/慢推不触发）
        checkWake(nowMs)
        // right after "光标居中" ignore stick motion until the stick is back in
        // the dead zone (or a timeout) — otherwise the release of a slightly
        // deflected stick moves the pointer away again ("second jump").
        // v1.66：只锁指针，不锁滚动（以前这里直接 return 会把右摇杆滚动也吞掉）。
        var pointerLocked = centerLock
        if (pointerLocked) {
            if (nowMs > centerLockUntil ||
                (Math.abs(axes[0]) < cDead && Math.abs(axes[1]) < cDead)
            ) {
                centerLock = false
                pointerLocked = false
            }
        }
        // 卡键自愈：真实按键不会按住 15s 以上，超时就当它丢了 up 事件
        if (pressedButtons.isNotEmpty()) {
            val stale = pressedButtons.filter { nowMs - (pressAt[it] ?: nowMs) > 15_000L }
            for (k in stale) {
                Log.i(TAG, "stale key dropped: $k (held >15s)")
                pressedButtons.remove(k)
                pressAt.remove(k)
                mixConsumed.remove(k)
                deferredSingles.remove(k)
                longFired.remove(k)
                for (i in 0 until Prefs.MIX_COUNT) if (mixKeys(i).contains(k)) mixFired[i] = false
            }
        }
        if (mixHoldAction.isNotEmpty()) {
            if (nowMs >= mixHoldStartAt && nowMs >= mixHoldNextAt) {
                mixHoldNextAt = nowMs + mixRepeatIntervalMs()
                repeatMixHold()
            }
        }
        if (pendingDowns.containsKey("r3")) {
            if (Math.abs(axes[12]) > cScrollDead || Math.abs(axes[13]) > cScrollDead) {
                pendingDowns.remove("r3")?.let { handler.removeCallbacks(it) }
                lastDownAt["r3"] = 0L
                Log.i(TAG, "double r3 cancelled (right stick moved)")
            }
        }
        val stickActive = Math.abs(axes[0]) > cDead || Math.abs(axes[1]) > cDead ||
            Math.abs(axes[12]) > cDead || Math.abs(axes[13]) > cDead
        if (stickActive) {
            lastUserInputAt = nowMs
            showPointer()
        }
        val dtSec = (dtScale * 16f / 1000f).toDouble()
        var dx = curve(axes[0] * cSensX, cDead)
        var dy = curve(axes[1] * cSensY, cDead)
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
        val pointerMoving = !pointerLocked && (dx != 0f || dy != 0f)
        if (pointerMoving) {
            // X + left stick = precision mode: much slower pointer for aiming
            val precision = pressedButtons.contains("x")
            var scale = if (precision) cPrecision else 1f
            // v1.66：估算位置改用「物理指针空间」（助手 c 回包同一坐标空间）
            if (ptrX.isNaN()) {
                ptrX = physOffX + physAppW / 2f
                ptrY = physOffY + physAppH / 2f
            }
            // edge slowdown (通用 §4.2)：按指针在应用区域内的相对位置
            val margin = 0.08f
            val nx0 = ((ptrX - physOffX) / physAppW).coerceIn(0f, 1f)
            val ny0 = ((ptrY - physOffY) / physAppH).coerceIn(0f, 1f)
            val nearEdge = nx0 < margin || nx0 > 1 - margin || ny0 < margin || ny0 > 1 - margin
            if (cEdgeSlow > 0 && nearEdge) {
                scale *= 1f - cEdgeSlow / 100f
                if (debugLogs && nowMs - lastEdgeLogAt > 1000L) {
                    lastEdgeLogAt = nowMs
                    Log.i(TAG, "edge slow active at ${ptrX.toInt()},${ptrY.toInt()} scale=$scale")
                }
            }
            val speed = cSpeedPhoneInt * scale
            if (nowMs >= arrowLockUntil) {
                // 应用空间 px → 物理指针空间 px（letterbox 缩放）
                val mx = dx * speed * dtScale * physScale
                val my = dy * speed * dtScale * physScale
                // 亚像素抖动不发（但不 return：右摇杆滚动/HAT 还要继续处理）
                if (Math.abs(mx) >= 0.2f || Math.abs(my) >= 0.2f) {
                    // 把这一帧的位移夹在「应用区域」内：系统不会把注入的 REL 位移夹回，
                    // 一旦推出去光标就落到应用窗口外（点击全部落空）。
                    // v1.66：增益用运行时标定值（旧版写死 2.16 → 估算与真实分离，
                    // 就是"边界卡死"的根因），并换算成物理空间。
                    val gNow = currentGain()
                    val rx = mx.coerceIn((physOffX - ptrX) / gNow, (physAppMaxX() - ptrX) / gNow)
                    val ry = my.coerceIn((physOffY - ptrY) / gNow, (physAppMaxY() - ptrY) / gNow)
                    val clampedX = rx != mx
                    val clampedY = ry != my
                    if (Math.abs(rx) >= 0.01f || Math.abs(ry) >= 0.01f) {
                        root.move(rx, ry)
                        relAccX += rx
                        relAccY += ry
                        if (clampedX || clampedY) relClamped = true
                        lastMoveSentAt = nowMs
                        if (nowMs - lastPtrLogAt > 300L) {
                            lastPtrLogAt = nowMs
                            Log.i(
                                TAG,
                                "ptr move dx=${rx.toInt()} dy=${ry.toInt()} at ${ptrX.toInt()},${ptrY.toInt()} " +
                                    "gain=$gNow scale=%.3f".format(physScale),
                            )
                        }
                        if ((clampedX || clampedY) && nowMs - lastEdgeLogAt > 500L) {
                            lastEdgeLogAt = nowMs
                            val (lx, ly) = physToLogical(ptrX, ptrY)
                            Log.i(TAG, "at app edge phys=${ptrX.toInt()},${ptrY.toInt()} logical=${lx.toInt()},${ly.toInt()} real=${lastRealX},${lastRealY}")
                        }
                        // 刚撞到夹取边界：立刻问一次真实位置，避免"估算到边 ≠ 真实到边"
                        if ((clampedX || clampedY) && !cursorQueryInFlight && nowMs - lastRealAt > 300L) {
                            sendCursorQuery(nowMs, false, allowGain = false)
                        }
                        ptrX = (ptrX + rx * gNow).coerceIn(physOffX, physAppMaxX())
                        ptrY = (ptrY + ry * gNow).coerceIn(physOffY, physAppMaxY())
                    }
                }
            }
        }
        // 停止推杆后不再做周期性"停手查询"：真实光标查询只在 L3 与撞夹取边界后按需发，
        // 避免空闲/长推时反复 fork dumpsys 把 CPU 拉高（t8 要求）。
        wasMovingPointer = pointerMoving

        // right stick -> wheel. A dedicated, larger dead zone (scroll_deadzone)
        // and a remap of [dead..1] to [0..1] keep a drifting or lightly touched
        // stick from scrolling, while still allowing fine slow scrolling.
        val scrollDead = cScrollDead
        var sy = axes[13]                       // AXIS_RY
        if (Math.abs(sy) < 0.02f) sy = axes[14] // AXIS_RZ (pads without RX/RY)
        val ny = scrollCurve(sy, scrollDead)
        var sx = axes[12]                       // AXIS_RX
        if (Math.abs(sx) < 0.02f) sx = axes[11] // AXIS_Z (pads without RX/RY)
        val nx = scrollCurve(sx, scrollDead)
        // v1.66 串扰仲裁：右摇杆斜推时同一 tick 只允许一种触摸手势（Z xor V）。
        // 真机实测 RX≥0.36 会同时起一条竖向 Z 和一条横向 V，两条 input swipe
        // 互相吞并（DIAG-v166 §2.4）；主导轴优先，另一轴让位。
        var vCan = ny != 0f
        var hCan = nx != 0f
        if (vCan && hCan) {
            if (Math.abs(sy) >= Math.abs(sx)) hCan = false else vCan = false
            if (nowMs - lastAxisArbLogAt > 500L) {
                lastAxisArbLogAt = nowMs
                Log.i(TAG, "gesture axis arbitration: RY=$sy RX=$sx -> ${if (vCan) "vertical" else "horizontal"}")
            }
        }

        // 控件级焦点: keep the scrollable-control rectangle fresh while the
        // right stick is scrolling (the helper dumps at most every 5 s)
        if (cVTouch) {
            // a real finger drag: ViewPager-style feeds (short-video pages)
            // only snap to a page after a drag; wheel steps leave them stuck
            // halfway between two pages
            if (vCan) {
                // holding the stick keeps paging: one drag per vertical cycle
                if (nowMs >= vSwipeCooldownUntil) {
                    // app-agnostic gesture policy: pull down = one shade pull
                    // from the top edge; push up = one long slow drag repeated
                    // back-to-back so the content keeps moving
                    // 摇杆向上 = 想看上面的内容 = 手指向下拖（内容跟手指往下走）；
                    // 摇杆向下 = 手指向上拖。起点用 30% / 65%，不要用 3%：
                    // 从顶部手势区起手会被系统当成「拉通知栏」，页面完全不动。
                    val up = ny < 0
                    val dist = (geomH * (if (up) 0.35f else 0.30f)).toInt().coerceIn(320, 1100)
                    val pct = if (up) 30 else 65
                    val dyy = if (up) dist else -dist
                    val ms = if (up) 220 else 380
                    val (cxp, cyp) = pointerPos()
                    root.swipeV(geomId, dyy, ms, geomW, geomH, pct, cxp.toInt(), cyp.toInt())
                    // v1.66：竖滑节奏由「滚动速度」控制（以前这个参数在触摸滚动模式下完全无效）
                    vSwipeCooldownUntil = nowMs + maxOf(ms + 20L, swipeRepeatMs())
                    if (debugLogs) Log.i(TAG, "vswipe $dyy on display $geomId cycle=${vSwipeCooldownUntil - nowMs}ms")
                }
            }
        } else if (ny != 0f) {
            val invert = if (cInvertScroll) -1f else 1f
            wheelAcc += -ny * invert * (cScrollSpeed * 0.05f) * dtScale
            val steps = wheelAcc.toInt()
            if (steps != 0) {
                wheelAcc -= steps
                root.wheel(steps)
            }
        } else {
            wheelAcc = 0f
        }

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

        // right stick X -> horizontal scrolling. REL_HWHEEL is ignored by many
        // touch-first apps (PiliPlus etc.), so this uses a real touch swipe
        // anchored at the mouse pointer (helper command V). v1.66: 横滑节奏与
        // 竖滑按同一"像素/秒"标定（横 0.45 屏宽/次，节奏受水平滑动速度控制），
        // 既不再"一次推杆翻十页"，也不再明显比竖向慢。
        if (hCan && nowMs >= hSwipeCooldownUntil) {
            // 横向用独立冷却 + 强制发送：刚做过竖滑（swipeCooldownUntil 未到）时
            // 也要能横向翻页；锚点始终用当前指针位置（helper 侧在任务内时以其为起手点）。
            // 指针可能被外部 P/c 移动而引擎估算仍是旧值：按住横向期间每 400ms 被动同步一次
            // 真实光标（`c` → CURSOR），下一次 swipe 就用真实锚点（t53/SCR-022）。
            if (nowMs - hCursorSyncAt >= 400L) {
                hCursorSyncAt = nowMs
                sendCursorQuery(nowMs, false, allowGain = false)
            }
            val hdir = if (nx > 0) -1 else 1
            val (hx, hy) = pointerPos()
            Log.i(TAG, "hswipe dir=$hdir nx=$nx anchor=${hx.toInt()},${hy.toInt()} hidden=$pointerHidden")
            doSwipe(false, hdir, slow = false, ignoreCooldown = true)
            hSwipeCooldownUntil = nowMs + hSwipeRepeatMs()
        }
        if (hScrollDir != 0) {
            if (nowMs - lastHScrollBtnAt >= wheelIntervalMs() * 3 / 2) {
                lastHScrollBtnAt = nowMs
                doSwipe(false, hScrollDir, slow = true)
            }
        }

        if (dragActive) {
            dragTick(nowMs)
        }

        if (wheelHold != 0) {
            if (nowMs - lastWheelHoldAt >= wheelIntervalMs()) {
                lastWheelHoldAt = nowMs
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

    private fun doSwipe(vertical: Boolean, dir: Int, slow: Boolean = false, widthPct: Int = 0, ignoreCooldown: Boolean = false) {
        if (dir == 0) return
        val now = SystemClock.elapsedRealtime()
        if (!ignoreCooldown && now < swipeCooldownUntil) return
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
        val display = geomId
        val w = geomW
        val h = geomH
        // the SLOW_* actions are short quick flicks: fast, but long enough to
        // actually trigger a system gesture (Lawnchair's app drawer needs about
        // a quarter of the screen; a 12% nudge just springs back)
        val ms = if (slow) 120 else 200
        // t20：指针被空闲隐藏后，先恢复指针再发滑动（一次 `j`，只重建设备、不做任何修正移动）。
        // 指针隐藏时也不存在“锚点失效”的外部可观测现象（helper 会回退 task 中心），
        // 但恢复后 swipe 锚点与用户最后位置一致，且与“下一次操作自动重建指针”的语义统一。
        if (pointerHidden) {
            val t0 = SystemClock.elapsedRealtime()
            showPointer()
            Log.i(TAG, "swipe anchor restore: pointer was hidden -> j (no move) took=${SystemClock.elapsedRealtime() - t0}ms")
        }
        if (vertical) {
            val dist = if (slow) (h * 0.25f).toInt().coerceIn(320, 900)
            else (h * 0.5f).toInt().coerceIn(420, 1800)
            // -1 = 以光标为锚点（在任务内时），助手只在光标不可用时退回任务中心
            val (cxp, cyp) = pointerPos()
            root.swipeV(display, if (dir > 0) dist else -dist, ms, w, h, -1, cxp.toInt(), cyp.toInt())
        } else {
            val dist = if (widthPct > 0) (w * widthPct / 100f).toInt().coerceIn(400, 1600)
            else if (slow) (w * 0.25f).toInt().coerceIn(320, 900)
            else (w * 0.45f).toInt().coerceIn(500, 1300)
            val (cxp, cyp) = pointerPos()
            root.swipeH(display, dir * dist, ms, w, h, -1, cxp.toInt(), cyp.toInt())
        }
        swipeCooldownUntil = now + ms + if (slow) 20 else 170
        if (debugLogs) Log.i(TAG, "swipe vertical=$vertical dir=$dir slow=$slow ms=$ms dist=${if (vertical) 0 else widthPct} display=$display")
    }

    private fun swipeStep(dir: Int) = doSwipe(false, dir)

    /**
     * 竖向连续滚动的节奏（一次手势的完整周期）。
     * v1.66 起「滚动速度」(scroll_speed) 在触摸滚动模式下真正生效：
     * 1..10 → 360..120 ms，默认 4 → 250 ms（与 v1.65 实测基线 250 ms 相同）。
     */
    private fun swipeRepeatMs(): Long =
        (410L - cScrollSpeed * 40L).coerceIn(120L, 380L)

    /**
     * 横向翻页节奏（水平滑动速度 hswipe_speed 1..10）。
     * v1.66：横滑每次 0.45 屏宽、节奏 540..300 ms（默认 7 → 420 ms），
     * 与竖向 560 px/250 ms ≈ 2240 px/s 对齐，横/竖位移比落在 0.8~1.25。
     * 旧公式 680−40×speed 在用户当前值 3 时是 560 ms（明显偏慢）。
     */
    private fun hSwipeRepeatMs(): Long =
        (560L - cHswipeSpeed * 20L).coerceIn(300L, 540L)

    private fun displaySize(id: Int): Pair<Int, Int> = displayState.size(id)

    /** one-shot horizontal swipe used by mix slots / wheel-left-right actions */
    private fun fireSwipeOnce(dir: Int, widthPct: Int = 0) = doSwipe(false, dir, false, widthPct)

    /**
     * 指针曲线：死区外归一化后 γ=1.6（v1.65 是 2.5）。
     * 真机基线：γ=2.5 时 0.24 推杆完全不动、0.49 推杆只有满推的 10.9%；
     * γ=1.6 + speed_phone=48 后：满推 ≈0.97 屏宽/300 ms，半推 ≈0.22 屏宽，
     * 0.24 推杆也有可感知位移（见 t3 验收数据）。
     */
    private fun curve(v: Float, dead: Float): Float {
        val a = Math.abs(v)
        if (a <= dead) return 0f
        val n = ((a - dead) / (1f - dead)).coerceIn(0f, 1f)
        return Math.signum(v) * Math.pow(n.toDouble(), 1.6).toFloat()
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
        Log.i(TAG, "helper ready: pointer device recreated (system keeps the position)")
        EngineState.connected = true
        EngineState.lastError = ""
        if (cForceLandscape) root.setRotation(1)
        // a (re)started helper has forwarding off: force a re-send
        dpadSent = false
        // 助手重启后光标可能被系统换了坐标：只"读"一次真实位置来校准估算，
        // 不发任何修正移动（保持"空闲隐藏/恢复原地不动"的语义）。
        refreshGeometry(force = true)
        cursorQueryInFlight = false
        centerActive = false
        engineHandler?.post { sendCursorQuery(SystemClock.elapsedRealtime(), false) }
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
        swipeHold = 0
        centerActive = false
        cursorQueryInFlight = false
        ptrX = Float.NaN
        ptrY = Float.NaN
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
