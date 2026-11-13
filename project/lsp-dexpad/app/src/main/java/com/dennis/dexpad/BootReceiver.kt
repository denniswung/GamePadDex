package com.dennis.dexpad

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Keeps the engine alive across reboots (the KernelSU module also starts it). */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val a = intent.action ?: return
        if (a == Intent.ACTION_BOOT_COMPLETED || a == Intent.ACTION_LOCKED_BOOT_COMPLETED) {
            EngineService.ensureRunning(context)
        }
    }
}
