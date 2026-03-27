package com.ctos.companion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Starts the CTOS protection service automatically after device reboot.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            CtosProtectionService.start(context)
        }
    }
}
