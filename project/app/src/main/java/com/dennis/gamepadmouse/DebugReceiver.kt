package com.dennis.gamepadmouse

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.util.Log

/**
 * Scripting / test hook (debug builds only).
 *
 *   adb shell am broadcast -a com.dennis.gamepadmouse.TOGGLE   -n com.dennis.gamepadmouse/.DebugReceiver
 *   adb shell am broadcast -a com.dennis.gamepadmouse.SNAP     -n ...
 *   adb shell am broadcast -a com.dennis.gamepadmouse.DEBUG    -n ... --ef mx 1208 --ef my 838
 *   adb shell am broadcast -a com.dennis.gamepadmouse.DEBUG    -n ... --ez double true
 *
 * It re-broadcasts inside the app so the service's non-exported receiver sees it.
 * Forwards nothing when the app is not debuggable.
 */
class DebugReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val debuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) return
        intent.getStringExtra("action")?.let { a ->
            gpmService?.runMappedAction(a, intent.getStringExtra("value") ?: "")
        }
        val action = intent.action ?: return
        val fwd = Intent(action).setPackage(context.packageName)
        when (action) {
            MouseAccessibilityService.ACTION_DEBUG -> {
                if (intent.hasExtra("mx")) fwd.putExtra("mx", intent.getFloatExtra("mx", -1f))
                if (intent.hasExtra("my")) fwd.putExtra("my", intent.getFloatExtra("my", -1f))
                if (intent.getBooleanExtra("double", false)) fwd.putExtra("double", true)
                if (intent.getBooleanExtra("click", false)) fwd.putExtra("click", true)
                intent.getStringExtra("mode")?.let { fwd.putExtra("mode", it) }
            }
        }
        Log.i("GpmDebug", "forward $action")
        context.sendBroadcast(fwd)
    }
}
