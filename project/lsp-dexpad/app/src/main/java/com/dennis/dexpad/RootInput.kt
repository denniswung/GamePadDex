package com.dennis.dexpad

import android.net.LocalSocket
import android.net.LocalSocketAddress
import android.os.SystemClock
import android.util.Log
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.File
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Bridge to the root helper (`gpminput`).
 *
 * The helper grabs every gamepad with EVIOCGRAB (so DeX / GameTools / the
 * foreground app never see the controller), streams the raw events here and owns
 * the virtual uinput mouse that this service drives with M / B / S commands.
 *
 * The helper is a daemon started by the KernelSU module at boot. One client at a
 * time is accepted; when the client goes away the helper releases the grab and
 * waits for the next one, which is why this class keeps retrying the connection.
 */
class RootInput(
    private val socketPath: String,
    private val listener: Listener,
) {
    interface Listener {
        fun onAxis(axis: Int, value: Float)
        fun onKey(keyCode: Int, action: Int)
        fun onReady()
        fun onLinkLost()
        fun onDevicesChanged(devices: List<String>)
        /** the physical d-pad was forwarded to the system (native navigation) */
        fun onPadKey(key: Int)
        /** a grabbed gamepad disappeared: its held keys will never send an up */
        fun onDeviceGone()
    }

    @Volatile
    private var socket: LocalSocket? = null

    @Volatile
    private var writer: BufferedWriter? = null

    private val running = AtomicBoolean(false)
    private val devices = ArrayList<String>()
    private val caps = HashMap<String, Int>()

    @Volatile
    var helperReady: Boolean = false
        private set

    /** timestamp of the last line from the helper (heartbeat) */
    @Volatile
    var lastLineAt: Long = 0L
        private set

    val isRunning: Boolean get() = running.get()

    /** drop the current socket and reconnect (helper restarted / stalled) */
    fun restart() {
        Log.i(TAG, "restarting link")
        running.set(false)
        try {
            socket?.shutdownInput()
        } catch (_: Throwable) {
        }
        try {
            socket?.close()
        } catch (_: Throwable) {
        }
        helperReady = false
        try {
            Thread.sleep(200)
        } catch (_: InterruptedException) {
        }
        start()
    }

    fun start() {
        if (running.getAndSet(true)) return
        Thread({ loop() }, "dexpad-link").apply { isDaemon = true }.start()
    }

    private fun loop() {
        while (running.get()) {
            var opened: LocalSocket? = null
            try {
                if (!File(socketPath).exists()) {
                    sleepQuietly(1500)
                    continue
                }
                val s = LocalSocket()
                s.connect(LocalSocketAddress(socketPath, LocalSocketAddress.Namespace.FILESYSTEM))
                opened = s
                socket = s
                writer = BufferedWriter(OutputStreamWriter(s.outputStream))
                Log.i(TAG, "connected to helper: $socketPath")
                readLoop(s)
            } catch (t: Throwable) {
                if (running.get()) Log.i(TAG, "helper link ended: ${t.message}")
            } finally {
                helperReady = false
                try {
                    writer?.close()
                } catch (_: Throwable) {
                }
                writer = null
                try {
                    opened?.close()
                } catch (_: Throwable) {
                }
                socket = null
                if (running.get()) listener.onLinkLost()
            }
            if (!running.get()) break
            sleepQuietly(1500)
        }
    }

    private fun readLoop(s: LocalSocket) {
        val reader = BufferedReader(InputStreamReader(s.inputStream))
        while (running.get()) {
            val line = reader.readLine() ?: break
            lastLineAt = SystemClock.elapsedRealtime()
            try {
                parse(line)
            } catch (t: Throwable) {
                Log.w(TAG, "bad helper line '$line': ${t.message}")
            }
        }
    }

    private fun parse(line: String) {
        when {
            line == "PING" -> Unit
            line == "READY" -> {
                helperReady = true
                Log.i(TAG, "helper ready")
                listener.onReady()
            }
            line.startsWith("PAD ") -> {
                val key = line.removePrefix("PAD ").trim().toIntOrNull() ?: return
                listener.onPadKey(key)
            }
            line.startsWith("DEV ") -> {
                val name = line.removePrefix("DEV ").substringAfter(' ', "")
                if (name.isNotEmpty()) devices.add(name)
                listener.onDevicesChanged(devices.toList())
            }
            line.startsWith("TOP ") -> EngineState.topPackage = line.removePrefix("TOP ").trim()
            line.startsWith("GONE ") -> {
                val name = line.removePrefix("GONE ").substringAfter(' ', "")
                devices.remove(name)
                listener.onDevicesChanged(devices.toList())
                listener.onDeviceGone()
            }
            line.startsWith("AX ") -> {
                val p = line.split(' ')
                if (p.size >= 4) {
                    val axis = p[2].toIntOrNull() ?: return
                    val value = p[3].toFloatOrNull() ?: return
                    listener.onAxis(axis, value)
                }
            }
            line.startsWith("KEY ") -> {
                val p = line.split(' ')
                if (p.size >= 4) {
                    val linux = p[2].toIntOrNull() ?: return
                    val down = (p[3].toIntOrNull() ?: 0) != 0
                    if (p.size >= 5) p[4].toLongOrNull()?.let { EngineState.lastEventMs = it }
                    val android = KeyMap.toAndroid(linux) ?: return
                    listener.onKey(android, if (down) 0 else 1)
                }
            }
            line == "SELFTEST begin" -> caps.clear()
            line == "SELFTEST end" -> {
                Log.i(TAG, "selftest " + caps.entries.joinToString(" ") { "${it.key}=${it.value}" })
                EngineState.caps = HashMap(caps)
            }
            line.startsWith("CAP ") -> {
                val p = line.split(' ')
                if (p.size >= 3) p[2].toIntOrNull()?.let { caps[p[1]] = it }
            }
            line.startsWith("ERR ") -> Log.w(TAG, "helper: $line")
        }
    }

    private fun sleepQuietly(ms: Long) {
        try {
            Thread.sleep(ms)
        } catch (_: InterruptedException) {
        }
    }

    fun send(line: String) {
        val w = writer ?: return
        try {
            synchronized(this) {
                w.write(line)
                w.write("\n")
                w.flush()
            }
        } catch (t: Throwable) {
            Log.w(TAG, "send '$line' failed: ${t.message}")
        }
    }

    /** 链路自检 (通用 §8.1): the helper answers with CAP <name> <0|1> lines */
    fun selftest() = send("?")

    fun move(dx: Float, dy: Float) = send(String.format(Locale.US, "M %.2f %.2f", dx, dy))

    fun button(index: Int, down: Boolean) = send("B $index ${if (down) 1 else 0}")

    fun wheel(steps: Int) {
        if (steps != 0) send("S $steps")
    }

    fun hWheel(steps: Int) {
        if (steps != 0) send("H $steps")
    }

    /**
     * Horizontal scrolling for touch-first apps: the helper injects a touch
     * drag anchored at the mouse pointer (many apps ignore REL_HWHEEL).
     */
    fun swipeH(display: Int, dx: Int, ms: Int, maxX: Int, maxY: Int, startPct: Int = -1) {
        if (dx != 0) send("V $display $dx $ms $maxX $maxY $startPct")
    }

    /**
     * vertical touch drag. startPct >= 0 starts the drag at that percentage of
     * the task height (pull-down/drawer gestures need a top-edge start).
     */
    fun swipeV(display: Int, dy: Int, ms: Int, maxX: Int, maxY: Int, startPct: Int = -1) {
        if (dy != 0) send("Z $display $dy $ms $maxX $maxY $startPct")
    }

    /** move the pointer to the centre of the display (park=true: phone screens) */
    /** press the power key (screen on/off), injected by the root helper */
    fun powerKey() {
        send("p")
    }

    /** force phone rotation: 1 landscape, 0 portrait, -1 automatic */
    fun setRotation(rot: Int) {
        send("r $rot")
    }

    fun centerCursor(maxX: Int, maxY: Int, park: Boolean = false, rotation: Int = 0, gain: Float = 2.16f) {
        send(String.format(java.util.Locale.US, "O %d %d %d %d %.2f",
            maxX, maxY, if (park) 1 else 0, rotation, gain))
    }

    /** switch to the next running app on the display (DeX ignores injected Alt+Tab) */
    fun switchApp(display: Int) {
        send("Y $display")
    }

    /** arrange the focused window: mode = max | left | right */
    fun arrangeWindow(display: Int, mode: String) {
        send("A $display $mode")
    }

    fun grab() = send("G")

    fun ungrab() = send("U")

    /** forward the physical d-pad to the helper's virtual gamepad (native d-pad) */
    fun passthrough(on: Boolean) = send(if (on) "I 1" else "I 0")

    /** close the focused app on the phone (force-stop; DeX uses ALT+F4) */
    fun closeApp() = send("L")

    /** force-stop the current foreground package (root helper, whitelisted) */
    fun forceStopTop() = send("f")

    /** 启动目标应用（走 root 的 am start，绕过后台启动限制） */
    fun openApp(pkg: String) = send("w $pkg")

    /* ---- 虚拟触摸屏：点击 / 长按 / 双指缩放 ---- */

    /** 触摸面尺寸（像素），用于把屏幕坐标换算成触摸坐标 */
    fun touchSize(w: Int, h: Int) = send("q $w $h")

    /** 单指触摸 down/up（真实触摸事件，支持长按） */
    fun touch(x: Float, y: Float, down: Boolean) =
        send(String.format(Locale.US, "k %d %d %d", x.toInt(), y.toInt(), if (down) 1 else 0))

    /** 双指缩放：dir 1=放大 -1=缩小 0=停止 */
    fun pinch(dir: Int, x: Float, y: Float) =
        send(String.format(Locale.US, "l %d %d %d", dir, x.toInt(), y.toInt()))

    /** inject one Android key code on a display (root helper runs `input -d`) */
    fun pointKey(displayId: Int, keyCode: Int) = send("D $displayId $keyCode")

    /** 方向键走虚拟手柄 HAT（系统会翻成 DPAD_*），dir: 1上 2下 3左 4右 */
    /** 查询当前前台包名（助手回 TOP <pkg>） */
    fun queryTop() = send("t")

    /** 直接发一条助手命令（仅调试/测试用） */
    fun raw(cmd: String) = send(cmd)

    fun hat(dir: Int, hold: Boolean = false) = send("A $dir " + if (hold) 1 else 0)

    /** inject a whole key combination on a display (helper runs `input keycombination`) */
    fun keyCombo(displayId: Int, codes: List<Int>) {
        if (codes.isEmpty()) return
        send("C $displayId ${codes.joinToString(" ")}")
    }

    /** pull the notification shade down (root helper runs `cmd statusbar expand-notifications`) */
    fun notifyPanel() = send("N")

    fun stop() {
        running.set(false)
        try {
            send("Q")
        } catch (_: Throwable) {
        }
        try {
            socket?.close()
        } catch (_: Throwable) {
        }
        socket = null
        writer = null
    }

    companion object {
        private const val TAG = "DexPadLink"
    }
}

/** Linux input-event key codes -> android.view.KeyEvent key codes. */
