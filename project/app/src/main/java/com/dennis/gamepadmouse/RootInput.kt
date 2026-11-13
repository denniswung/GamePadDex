package com.dennis.gamepadmouse

import android.content.Context
import android.net.LocalSocket
import android.net.LocalSocketAddress
import android.util.Log
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.File
import java.io.InputStream
import java.io.InputStreamReader
import java.io.OutputStream
import java.io.OutputStreamWriter
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Root side of the DeX fix.
 *
 * The bundled `gpminput` helper grabs every gamepad with EVIOCGRAB - from that
 * moment the Android framework (DeX desktop, GameTools, the foreground app)
 * receives **no** events from the controller, which is exactly what "block
 * Samsung's built-in gamepad control" means - and streams the raw events back
 * to us so we can drive the pointer ourselves.
 *
 * It also owns a virtual mouse / keyboard (uinput) that we inject into when
 * "native pointer" mode is on.
 *
 * Two transports are supported:
 *  - unix socket (helper started by an init script / adb, path in
 *    [Prefs.HELPER_SOCKET]) - handy because it needs no per-launch `su`;
 *  - `su -c <binary>` with the helper's stdio wired to us (default).
 */
class RootInput(
    private val context: Context,
    private val listener: Listener,
    private val socketPath: String? = null,
) {
    interface Listener {
        fun onAxis(axis: Int, value: Float)
        fun onKey(keyCode: Int, action: Int)
        fun onReady()
        fun onCursorPos(x: Float, y: Float)
        fun onDevicesChanged(names: List<String>)
        fun onLog(line: String)
    }

    @Volatile
    private var process: Process? = null
    private var socket: LocalSocket? = null
    private var writer: BufferedWriter? = null
    private val running = AtomicBoolean(false)
    private var readerThread: Thread? = null
    private var errThread: Thread? = null

    val isRunning: Boolean get() = running.get()

    /** true once the helper printed READY (devices scanned, injection ready) */
    @Volatile
    var helperReady: Boolean = false
        private set

    fun grab() = send("G")
    fun ungrab() = send("U")

    fun binary(): File {
        val f = File(context.filesDir, "gpminput")
        if (!f.exists() || f.length() == 0L) {
            context.assets.open("gpminput").use { input ->
                f.outputStream().use { out -> input.copyTo(out) }
            }
            f.setExecutable(true, false)
        }
        return f
    }

    fun start() {
        if (running.getAndSet(true)) return
        Thread {
            try {
                var ok = trySocketTransport()
                if (!ok && File("/data/adb/modules/gpm_dex").exists()) {
                    // the KernelSU module owns the helper: never spawn a second
                    // instance (the two would fight over the EVIOCGRAB), just wait
                    while (!ok && running.get()) {
                        for (i in 0 until 10) {
                            Thread.sleep(500)
                            if (!running.get()) break
                            if (trySocketTransport()) { ok = true; break }
                        }
                    }
                    return@Thread
                }
                if (!ok) launchProcess()
            } catch (t: Throwable) {
                Log.e(TAG, "failed to start helper", t)
                listener.onLog("helper start failed: ${t.message}")
                running.set(false)
            }
        }.apply { name = "gpm-root-start" }.start()
    }

    private fun trySocketTransport(): Boolean {
        val path = socketPath?.takeIf { it.isNotBlank() } ?: return false
        return try {
            if (!File(path).exists()) return false
            val s = LocalSocket()
            s.connect(LocalSocketAddress(path, LocalSocketAddress.Namespace.FILESYSTEM))
            socket = s
            Log.i(TAG, "connected to helper socket $path")
            attachStreams(s.inputStream, s.outputStream)
            true
        } catch (t: Throwable) {
            Log.i(TAG, "socket $path not available (${t.message}), using su")
            false
        }
    }

    private fun launchProcess() {
        val bin = binary()
        // `su` is not always on the app's PATH; try the usual absolute locations
        // and finally the plain name before giving up and staying in the
        // accessibility fallback.
        val candidates = if (android.os.Process.myUid() == 0) {
            listOf(arrayOf(bin.absolutePath))
        } else {
            listOf(
                arrayOf("/system/bin/su", "-c", bin.absolutePath),
                arrayOf("/debug_ramdisk/su", "-c", bin.absolutePath),
                arrayOf("su", "-c", bin.absolutePath),
            )
        }
        var started: Process? = null
        var lastError: Throwable? = null
        for (cmd in candidates) {
            try {
                Log.i(TAG, "starting ${cmd.joinToString(" ")}")
                started = ProcessBuilder(*cmd).start()
                break
            } catch (t: Throwable) {
                lastError = t
                Log.w(TAG, "start failed (${cmd.first()}): ${t.message}")
            }
        }
        val p = started ?: throw (lastError ?: IllegalStateException("no su"))
        process = p
        attachStreams(p.inputStream, p.outputStream)
        errThread = Thread {
            try {
                BufferedReader(InputStreamReader(p.errorStream)).use { r ->
                    while (true) {
                        val line = r.readLine() ?: break
                        if (line.isNotBlank()) Log.w(TAG, "stderr: $line")
                    }
                }
            } catch (_: Throwable) {
            }
        }.apply { name = "gpm-root-err"; start() }
        val code = p.waitFor()
        Log.i(TAG, "helper exited with $code")
        running.set(false)
        helperReady = false
        listener.onDevicesChanged(emptyList())
    }

    private fun attachStreams(input: InputStream, output: OutputStream) {
        writer = BufferedWriter(OutputStreamWriter(output))
        val devices = ArrayList<String>()
        readerThread = Thread {
            try {
                BufferedReader(InputStreamReader(input)).use { r ->
                    while (true) {
                        val line = r.readLine() ?: break
                        handleLine(line, devices)
                    }
                }
            } catch (t: Throwable) {
                if (running.get()) Log.w(TAG, "link ended: ${t.message}")
            }
        }.apply { name = "gpm-root-out"; start() }
    }

    private fun handleLine(line: String, devices: MutableList<String>) {
        when {
            line == "READY" -> {
                helperReady = true
                Log.i(TAG, "helper ready")
                listener.onReady()
            }
            line.startsWith("DEV ") -> {
                val name = line.removePrefix("DEV ").substringAfter(' ', "")
                if (name.isNotEmpty()) devices.add(name)
                Log.i(TAG, "gamepad: $name")
                listener.onDevicesChanged(devices.toList())
            }
            line.startsWith("GRABBED ") -> Log.i(TAG, "grabbed: ${line.removePrefix("GRABBED ")}")
            line.startsWith("GONE ") -> {
                val name = line.removePrefix("GONE ").substringAfter(' ', "")
                devices.remove(name)
                listener.onDevicesChanged(devices.toList())
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
                    val android = KeyMap.toAndroid(linux) ?: return
                    listener.onKey(android, if (down) 0 else 1)
                }
            }
            line.startsWith("CURSOR ") -> {
                val p = line.split(' ')
                if (p.size >= 3) {
                    val x = p[1].toFloatOrNull() ?: -1f
                    val y = p[2].toFloatOrNull() ?: -1f
                    if (x >= 0f && y >= 0f) listener.onCursorPos(x, y)
                }
            }
            line.startsWith("ERR ") -> {
                Log.w(TAG, line)
                listener.onLog(line)
            }
        }
    }

    /** sends one protocol line to the helper */
    fun send(line: String) {
        val w = writer ?: return
        try {
            synchronized(this) {
                w.write(line)
                w.write("\n")
                w.flush()
            }
        } catch (t: Throwable) {
            Log.w(TAG, "send failed: ${t.message}")
        }
    }

    fun move(dx: Float, dy: Float) = send("M $dx $dy")
    fun button(btn: Int, down: Boolean) = send("B $btn ${if (down) 1 else 0}")
    fun wheel(steps: Int) = send("S $steps")
    fun hWheel(steps: Int) = send("H $steps")
    fun key(linuxCode: Int, down: Boolean) = send("K $linuxCode ${if (down) 1 else 0}")
    fun regrab() = send("R")

    /** ask the helper for the real system pointer position */
    fun queryCursor() = send("W")

    /** bring the home screen up on a specific display (DeX launcher) */
    fun dexHome(displayId: Int): Boolean {
        if (!isRunning) return false
        send("E $displayId")
        return helperReady
    }

    /** click the DeX caption fullscreen button (root, coordinates resolved on the fly) */
    fun fullscreenClick(displayId: Int, screenWidth: Int = 0, screenHeight: Int = 0): Boolean {
        if (!isRunning) return false
        send("J $displayId $screenWidth $screenHeight")
        return true            // fire and forget: helperReady lags right after a restart
    }

    /** relaunch a component in fullscreen windowing mode on a display (root) */
    fun relaunchFullscreen(displayId: Int, component: String): Boolean {
        if (!isRunning) return false
        send("F $displayId $component")
        return helperReady
    }

    /** inject a keyboard combo ("ctrl+alt+f") on a display (root) */
    fun pointCombo(displayId: Int, combo: String): Boolean {
        if (!isRunning) return false
        send("X $displayId $combo")
        return helperReady
    }

    /** inject a key event on a specific display (root) */
    fun pointKey(displayId: Int, keyCode: Int): Boolean {
        if (!isRunning) return false
        send("D $displayId $keyCode")
        return helperReady
    }

    /** ask the root injector for a real ACTION_SCROLL event at (x,y) */
    fun pointScroll(x: Float, y: Float, dy: Float, dx: Float, displayId: Int): Boolean {
        if (!isRunning) return false
        send("P $x $y $dy $dx $displayId")
        return helperReady
    }

    fun stop() {
        running.set(false)
        try {
            send("Q")
        } catch (_: Throwable) {
        }
        val p = process
        process = null
        writer = null
        if (p != null) {
            try {
                if (!p.waitFor(400, java.util.concurrent.TimeUnit.MILLISECONDS)) p.destroy()
            } catch (_: Throwable) {
                p.destroy()
            }
        }
        try {
            socket?.close()
        } catch (_: Throwable) {
        }
        socket = null
        readerThread?.interrupt()
        errThread?.interrupt()
    }

    companion object {
        private const val TAG = "GpmRootInput"

        /** true when a root shell answered (blocking; call off the main thread) */
        fun hasRoot(): Boolean = try {
            val p = ProcessBuilder("su", "-c", "id").redirectErrorStream(true).start()
            val out = p.inputStream.bufferedReader().readText()
            p.waitFor(2, java.util.concurrent.TimeUnit.SECONDS)
            out.contains("uid=0")
        } catch (t: Throwable) {
            false
        }
    }
}

/** Linux input-event key codes -> android.view.KeyEvent key codes. */
object KeyMap {
    private val table = HashMap<Int, Int>().apply {
        // gamepad
        put(0x130, 96)   // BTN_SOUTH  -> BUTTON_A
        put(0x131, 97)   // BTN_EAST   -> BUTTON_B
        put(0x133, 99)   // BTN_NORTH  -> BUTTON_X
        put(0x134, 100)  // BTN_WEST   -> BUTTON_Y
        put(0x136, 102)  // BTN_TL     -> BUTTON_L1
        put(0x137, 103)  // BTN_TR     -> BUTTON_R1
        put(0x138, 104)  // BTN_TL2    -> BUTTON_L2
        put(0x139, 105)  // BTN_TR2    -> BUTTON_R2
        put(0x13a, 109)  // BTN_SELECT -> BUTTON_SELECT
        put(0x13b, 108)  // BTN_START  -> BUTTON_START
        put(0x13c, 110)  // BTN_MODE   -> BUTTON_MODE
        put(0x13d, 106)  // BTN_THUMBL -> BUTTON_THUMBL
        put(0x13e, 107)  // BTN_THUMBR -> BUTTON_THUMBR
        put(0x220, 19)   // BTN_DPAD_UP
        put(0x221, 20)   // BTN_DPAD_DOWN
        put(0x222, 21)   // BTN_DPAD_LEFT
        put(0x223, 22)   // BTN_DPAD_RIGHT
        for (i in 0..15) put(0x2c0 + i, 188 + i) // BTN_TRIGGER_HAPPY1..16 -> BUTTON_1..16
        // navigation / media commonly found on controllers
        put(158, 4)      // KEY_BACK
        put(172, 3)      // KEY_HOMEPAGE
        put(139, 82)     // KEY_MENU
        put(116, 26)     // KEY_POWER
        put(115, 24)     // KEY_VOLUMEUP
        put(114, 25)     // KEY_VOLUMEDOWN
        put(113, 164)    // KEY_MUTE
        put(164, 85)     // KEY_PLAYPAUSE
        put(163, 87)     // KEY_NEXTSONG
        put(165, 88)     // KEY_PREVIOUSSONG
        put(103, 19)     // KEY_UP
        put(108, 20)     // KEY_DOWN
        put(105, 21)     // KEY_LEFT
        put(106, 22)     // KEY_RIGHT
        put(28, 66)      // KEY_ENTER
        put(1, 111)      // KEY_ESC
        put(57, 62)      // KEY_SPACE
        put(15, 61)      // KEY_TAB
        // letters: KEY_A(30)..KEY_Z(54) -> 29..53
        for (i in 0 until 26) put(30 + i, 29 + i)
    }

    fun toAndroid(linuxCode: Int): Int? = table[linuxCode]

    /** android key code -> linux code, used for the virtual keyboard injection */
    private val reverse by lazy {
        val m = HashMap<Int, Int>()
        table.forEach { (linux, android) -> m.putIfAbsent(android, linux) }
        m
    }

    fun toLinux(androidCode: Int): Int? = reverse[androidCode]
}
