package com.ctos.companion

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Foreground service that keeps CTOS Companion alive in the background,
 * shows the persistent "dispositivo protetto" status notification, and
 * surfaces security alerts as real Android notifications.
 */
class CtosProtectionService : Service() {

    companion object {
        const val PERSISTENT_CHANNEL = "ctos_protection"
        const val ALERT_CHANNEL      = "ctos_alerts"
        const val PERSISTENT_NOTIF   = 1001

        // Extras for alert notifications
        const val EXTRA_ALERT_TITLE  = "alert_title"
        const val EXTRA_ALERT_BODY   = "alert_body"
        const val EXTRA_ALERT_LEVEL  = "alert_level" // 1=info 3=warning 5=critical
        const val ACTION_SHOW_ALERT  = "com.ctos.companion.SHOW_ALERT"

        fun start(context: Context) {
            val intent = Intent(context, CtosProtectionService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CtosProtectionService::class.java))
        }

        /** Send a security alert notification (callable even when app is in background) */
        fun showAlert(context: Context, title: String, body: String, level: Int = 3) {
            val intent = Intent(context, CtosProtectionService::class.java).apply {
                action = ACTION_SHOW_ALERT
                putExtra(EXTRA_ALERT_TITLE, title)
                putExtra(EXTRA_ALERT_BODY,  body)
                putExtra(EXTRA_ALERT_LEVEL, level)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private lateinit var nm: NotificationManager

    override fun onCreate() {
        super.onCreate()
        nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createChannels()
        startForeground(PERSISTENT_NOTIF, buildPersistentNotification())
        schedulePeriodicScan()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_SHOW_ALERT) {
            val title = intent.getStringExtra(EXTRA_ALERT_TITLE) ?: "CTOS Alert"
            val body  = intent.getStringExtra(EXTRA_ALERT_BODY)  ?: ""
            val level = intent.getIntExtra(EXTRA_ALERT_LEVEL, 3)
            pushAlertNotification(title, body, level)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun schedulePeriodicScan() {
        val request = PeriodicWorkRequestBuilder<CtosBackgroundWorker>(6, TimeUnit.HOURS)
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            CtosBackgroundWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }

    // ── Notification channels ──────────────────────────────────────────────────

    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // Persistent status (silent, low importance)
        nm.createNotificationChannel(
            NotificationChannel(PERSISTENT_CHANNEL, "Protezione CTOS",
                NotificationManager.IMPORTANCE_LOW).apply {
                description = "Stato della protezione CTOS Companion"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            })
        // Alerts (high importance, with sound)
        nm.createNotificationChannel(
            NotificationChannel(ALERT_CHANNEL, "Avvisi sicurezza CTOS",
                NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Avvisi di minacce rilevate da CTOS"
            })
    }

    // ── Persistent notification ────────────────────────────────────────────────

    private fun buildPersistentNotification(): Notification {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, PERSISTENT_CHANNEL)
            .setContentTitle("CTOS Companion")
            .setContentText("Dispositivo protetto • Guardian attivo")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pi)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    // ── Security alert notification ────────────────────────────────────────────

    private fun pushAlertNotification(title: String, body: String, level: Int) {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, System.currentTimeMillis().toInt(), launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val priority = when {
            level >= 4 -> NotificationCompat.PRIORITY_HIGH
            level >= 3 -> NotificationCompat.PRIORITY_DEFAULT
            else       -> NotificationCompat.PRIORITY_LOW
        }
        val notif = NotificationCompat.Builder(this, ALERT_CHANNEL)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(priority)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()

        nm.notify(System.currentTimeMillis().toInt(), notif)
    }
}
