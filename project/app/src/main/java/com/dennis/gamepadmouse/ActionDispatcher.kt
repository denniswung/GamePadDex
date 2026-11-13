package com.dennis.gamepadmouse

import android.accessibilityservice.AccessibilityService
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.hardware.HardwareBuffer
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import java.io.OutputStream

/** All "button action" implementations. */
object ActionDispatcher {
    private const val TAG = "GpmAction"

    fun run(
        service: MouseAccessibilityService,
        prefs: SharedPreferences,
        action: String,
        value: String,
        slot: String = "",
    ) {
        Log.i(TAG, "action=$action value=$value slot=$slot")
        when (action) {
            "none" -> Unit
            "home" -> service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
            "recents" -> service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_RECENTS)
            "vol_up" -> volume(service, true)
            "vol_down" -> volume(service, false)
            "mute" -> mute(service)
            "bright_up" -> brightness(service, +12)
            "bright_down" -> brightness(service, -12)
            "media_forward" -> key(service, KeyEvent.KEYCODE_MEDIA_FAST_FORWARD)
            "media_rewind" -> key(service, KeyEvent.KEYCODE_MEDIA_REWIND)
            "screenshot" -> screenshot(service)
            "rotate" -> rotate(service)
            "launch_app" -> launch(service, value)
            "click_location" -> clickLocation(service, prefs, value, slot, false)
            "click_location_repeat" -> clickLocation(service, prefs, value, slot, true)
            else -> Log.w(TAG, "unknown action $action")
        }
    }

    fun back(service: MouseAccessibilityService) {
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
    }

    private fun key(service: AccessibilityService, code: Int) {
        // media transport keys go through AudioManager.dispatchMediaKeyEvent
        try {
            val am = service.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (code == KeyEvent.KEYCODE_MEDIA_FAST_FORWARD) {
                am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_FAST_FORWARD))
                am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_FAST_FORWARD))
            } else {
                am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_REWIND))
                am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_REWIND))
            }
        } catch (t: Throwable) {
            Log.w(TAG, "media key failed: ${t.message}")
        }
    }

    private fun volume(service: Context, up: Boolean) {
        try {
            val am = service.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                if (up) AudioManager.ADJUST_RAISE else AudioManager.ADJUST_LOWER,
                AudioManager.FLAG_SHOW_UI,
            )
        } catch (t: Throwable) {
            Log.w(TAG, "volume failed: ${t.message}")
        }
    }

    private fun mute(service: Context) {
        try {
            val am = service.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val muted = am.isStreamMute(AudioManager.STREAM_MUSIC)
            am.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                if (muted) AudioManager.ADJUST_UNMUTE else AudioManager.ADJUST_MUTE,
                AudioManager.FLAG_SHOW_UI,
            )
        } catch (t: Throwable) {
            Log.w(TAG, "mute failed: ${t.message}")
        }
    }

    private fun brightness(service: Context, delta: Int) {
        try {
            if (!Settings.System.canWrite(service)) {
                val i = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                i.data = Uri.parse("package:${service.packageName}")
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                service.startActivity(i)
                return
            }
            val cur = Settings.System.getInt(
                service.contentResolver, Settings.System.SCREEN_BRIGHTNESS, 128
            )
            val next = (cur + delta).coerceIn(10, 255)
            Settings.System.putInt(service.contentResolver, Settings.System.SCREEN_BRIGHTNESS, next)
        } catch (t: Throwable) {
            Log.w(TAG, "brightness failed: ${t.message}")
        }
    }

    private fun rotate(service: Context) {
        try {
            if (!Settings.System.canWrite(service)) {
                val i = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                i.data = Uri.parse("package:${service.packageName}")
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                service.startActivity(i)
                return
            }
            val auto = Settings.System.getInt(
                service.contentResolver, Settings.System.ACCELEROMETER_ROTATION, 1
            )
            Settings.System.putInt(
                service.contentResolver, Settings.System.ACCELEROMETER_ROTATION, if (auto == 1) 0 else 1
            )
        } catch (t: Throwable) {
            Log.w(TAG, "rotate failed: ${t.message}")
        }
    }

    private fun launch(service: Context, pkg: String) {
        if (pkg.isBlank()) return
        try {
            val intent = service.packageManager.getLaunchIntentForPackage(pkg) ?: return
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            service.startActivity(intent)
        } catch (t: Throwable) {
            Log.w(TAG, "launch $pkg failed: ${t.message}")
        }
    }

    private fun clickLocation(
        service: MouseAccessibilityService,
        prefs: SharedPreferences,
        value: String,
        slot: String,
        repeat: Boolean,
    ) {
        val parts = value.split(",")
        if (parts.size != 2) {
            // no location stored yet -> capture the current pointer position
            val pos = service.pointerEngine?.pos ?: return
            if (slot.isNotEmpty()) {
                prefs.edit()
                    .putString(Prefs.mappingValue(slot), String.format("%.1f,%.1f", pos.x, pos.y))
                    .apply()
            }
            toast(service, "Location captured: ${pos.x.toInt()}, ${pos.y.toInt()}")
            return
        }
        val x = parts[0].toFloatOrNull() ?: return
        val y = parts[1].toFloatOrNull() ?: return
        if (repeat) {
            val interval = if (slot.isNotEmpty()) {
                prefs.getInt(Prefs.mappingInterval(slot), prefs.getInt(Prefs.REPEAT_INTERVAL, 500))
            } else {
                prefs.getInt(Prefs.REPEAT_INTERVAL, 500)
            }
            service.startRepeatClick(x, y, interval)
        } else {
            service.pointerEngine?.clickAt(x, y)
        }
    }

    fun toast(service: Context, msg: String) {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try {
                android.widget.Toast.makeText(service, msg, android.widget.Toast.LENGTH_SHORT).show()
            } catch (_: Throwable) {
            }
        }
    }

    /** grabs a screenshot with the accessibility API and stores it in Pictures/Screenshots */
    fun screenshot(service: AccessibilityService) {
        if (Build.VERSION.SDK_INT < 30) return
        val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
        val targetDisplay = (service as? MouseAccessibilityService)?.pointerEngine?.display?.displayId
            ?: android.view.Display.DEFAULT_DISPLAY
        try {
            service.takeScreenshot(
                targetDisplay,
                executor,
                object : AccessibilityService.TakeScreenshotCallback {
                    override fun onSuccess(result: AccessibilityService.ScreenshotResult) {
                        try {
                            val hb: HardwareBuffer = result.hardwareBuffer
                            val bmp = Bitmap.wrapHardwareBuffer(hb, result.colorSpace)
                                ?: return
                            val sw = Bitmap.createBitmap(bmp)
                            save(service, sw)
                            hb.close()
                        } catch (t: Throwable) {
                            Log.w(TAG, "screenshot save failed: ${t.message}")
                        }
                    }

                    override fun onFailure(errorCode: Int) {
                        Log.w(TAG, "screenshot failed $errorCode")
                    }
                })
        } catch (t: Throwable) {
            Log.w(TAG, "screenshot failed: ${t.message}")
        } finally {
            executor.shutdown()
        }
    }

    private fun save(context: Context, bmp: Bitmap) {
        val name = "gpm_" + System.currentTimeMillis() + ".png"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                Environment.DIRECTORY_PICTURES + "/Screenshots"
            )
        }
        val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return
        context.contentResolver.openOutputStream(uri)?.use { out: OutputStream ->
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
    }
}
