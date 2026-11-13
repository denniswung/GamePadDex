package com.dennis.gamepadmouse

import android.net.LocalSocket
import android.net.LocalSocketAddress
import android.util.Log
import java.io.BufferedWriter
import java.io.File
import java.io.OutputStreamWriter
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Client for the root scroll injector daemon (`ScrollInject`, run via
 * `app_process` as root).  It injects real `ACTION_SCROLL` mouse events at an
 * absolute coordinate on a chosen display - this is the same mechanism the
 * DeX touchpad uses, so scrolling is event-smooth instead of a series of
 * synthetic touch swipes.
 */
class ScrollInjector(private val socketPath: String) {
    /** abstract-namespace socket name, e.g. "gpm_scroll" */
    private var socket: LocalSocket? = null
    private var writer: BufferedWriter? = null
    private val connecting = AtomicBoolean(false)

    val isOpen: Boolean get() = writer != null

    private fun ensure(): BufferedWriter? {
        writer?.let { return it }

        if (!connecting.compareAndSet(false, true)) return null
        return try {
            val s = LocalSocket()
            s.connect(LocalSocketAddress(socketPath, LocalSocketAddress.Namespace.ABSTRACT))
            socket = s
            val w = BufferedWriter(OutputStreamWriter(s.outputStream))
            writer = w
            Log.i(TAG, "connected to scroll injector")
            w
        } catch (t: Throwable) {
            Log.i(TAG, "injector not available: ${t.message}")
            null
        } finally {
            connecting.set(false)
        }
    }

    /** dx/dy in wheel "lines" (positive dy scrolls content up) */
    fun scroll(x: Float, y: Float, dy: Float, dx: Float, displayId: Int): Boolean {
        val w = ensure() ?: return false
        return try {
            synchronized(this) {
                w.write("$x $y $dy $dx $displayId\n")
                w.flush()
            }
            true
        } catch (t: Throwable) {
            Log.w(TAG, "scroll send failed: ${t.message}")
            close()
            false
        }
    }

    fun close() {
        try {
            writer?.close()
        } catch (_: Throwable) {
        }
        try {
            socket?.close()
        } catch (_: Throwable) {
        }
        writer = null
        socket = null
    }

    companion object {
        private const val TAG = "GpmInjector"
    }
}
