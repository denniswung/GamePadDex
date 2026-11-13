package com.dennis.dexpad

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.util.Log

/**
 * Debug-build only scripting hook (same idea as the old replica app):
 *
 *   adb shell am broadcast -a com.dennis.dexpad.DEBUG \
 *       -n com.dennis.dexpad/.DebugReceiver --es button x --es mapped recents
 *   adb shell am broadcast -a com.dennis.dexpad.DEBUG \
 *       -n com.dennis.dexpad/.DebugReceiver --es button y --es mapped key_combo --es value ctrl+alt+f
 *   adb shell am broadcast -a com.dennis.dexpad.MODE \
 *       -n com.dennis.dexpad/.DebugReceiver --ez enabled false
 */
class DebugReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val debuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) return
        val prefs = Prefs(context)
        when (intent.action) {
            "com.dennis.dexpad.DEBUG" -> {
                // generic preference override, e.g. --es pref scroll_deadzone --ei ival 400
                intent.getStringExtra("pref")?.let { pref ->
                    val e = prefs.shared.edit()
                    if (intent.hasExtra("ival")) e.putInt(pref, intent.getIntExtra("ival", 0))
                    if (intent.hasExtra("sval")) e.putString(pref, intent.getStringExtra("sval"))
                    if (intent.hasExtra("bval")) e.putBoolean(pref, intent.getBooleanExtra("bval", false))
                    e.apply()
                    Log.i("DexPadDebug", "pref $pref ival=${intent.getIntExtra("ival", Int.MIN_VALUE)} sval=${intent.getStringExtra("sval")}")
                    return
                }
                val button = intent.getStringExtra("button") ?: return
                val mapped = intent.getStringExtra("mapped") ?: return
                prefs.setAction(button, mapped)
                intent.getStringExtra("value")?.let { prefs.setCombo(button, it) }
                Log.i("DexPadDebug", "set $button -> $mapped (${intent.getStringExtra("value") ?: ""})")
            }
            "com.dennis.dexpad.CONFIG" -> {
                when (intent.getStringExtra("op")) {
                    "export" -> {
                        val f = java.io.File(context.filesDir, "dexpad-config.json")
                        f.writeText(prefs.exportJson())
                        Log.i("DexPadDebug", "export -> ${f.absolutePath} ${f.length()}B")
                    }
                    "import" -> {
                        val f = java.io.File(context.filesDir, "dexpad-config.json")
                        val ok = f.exists() && prefs.importJson(f.readText())
                        Log.i("DexPadDebug", "import ok=$ok")
                    }
                    "save" -> {
                        val n = intent.getStringExtra("name") ?: "default"
                        prefs.saveProfile(n)
                        Log.i("DexPadDebug", "profile save $n")
                    }
                    "load" -> {
                        val n = intent.getStringExtra("name") ?: "default"
                        Log.i("DexPadDebug", "profile load $n ok=${prefs.loadProfile(n)}")
                    }
                }
            }
            // 直接向 root 助手发一条命令（仅调试用，例如 h 隐藏指针 / j 恢复）
            "com.dennis.dexpad.HCMD" -> {
                val cmd = intent.getStringExtra("cmd") ?: return
                Log.i("DexPadDebug", "hcmd '$cmd' -> ${EngineBridge.sendRaw(cmd)}")
            }
            "com.dennis.dexpad.MODE" -> {
                prefs.enabled = intent.getBooleanExtra("enabled", !prefs.enabled)
                Log.i("DexPadDebug", "enabled=${prefs.enabled}")
            }
        }
    }
}
