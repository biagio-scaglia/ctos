package com.ctos.companion

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Fires when a new app is installed on the device.
 * Shows a notification inviting the user to scan it with CTOS.
 */
class PackageInstallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_PACKAGE_ADDED) return
        val packageName = intent.data?.schemeSpecificPart ?: return
        // Ignore system updates (replacing=true means update, not new install)
        if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return

        val pm = context.packageManager
        val appName = try {
            pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
        } catch (e: Exception) { packageName }

        showInstallNotification(context, appName, packageName)
    }

    private fun showInstallNotification(context: Context, appName: String, packageName: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "ctos_install"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(channelId, "Nuove app rilevate",
                    NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "CTOS rileva le nuove app installate"
                })
        }

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(
            context, packageName.hashCode(), launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(context, channelId)
            .setContentTitle("Nuova app installata")
            .setContentText("\"$appName\" è stata installata. Apri CTOS per analizzarla.")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_RECOMMENDATION)
            .build()

        nm.notify(packageName.hashCode(), notif)
    }
}
