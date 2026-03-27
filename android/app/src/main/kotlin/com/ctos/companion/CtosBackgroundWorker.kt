package com.ctos.companion

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.io.File
import java.util.Calendar

/**
 * Runs every 6 hours in the background (even when the app is closed).
 * - Checks for suspicious newly-installed apps
 * - Checks for Tor/suspicious TCP connections
 * - Sends a daily morning briefing at 8 AM
 * - Updates SharedPreferences so the home widget can refresh its data
 */
class CtosBackgroundWorker(
    private val ctx: Context,
    params: WorkerParameters
) : Worker(ctx, params) {

    companion object {
        const val WORK_NAME     = "ctos_periodic_scan"
        const val PREFS_NAME    = "ctos_widget"
        const val KEY_RISK      = "risk_score"
        const val KEY_VPN       = "vpn_active"
        const val KEY_LAST_SCAN = "last_scan"
        const val KEY_KNOWN_PKGS= "known_packages"
        const val BRIEFING_HOUR = 8
    }

    override fun doWork(): Result {
        val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // ── 1. Detect newly installed suspicious apps ──────────────
        val pm = ctx.packageManager
        val currentPkgs = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .map { it.packageName }
            .toSet()

        val knownJson = prefs.getString(KEY_KNOWN_PKGS, "") ?: ""
        val knownPkgs = if (knownJson.isEmpty()) emptySet()
            else knownJson.split(",").toSet()

        val newPkgs = currentPkgs - knownPkgs
        if (newPkgs.isNotEmpty() && knownPkgs.isNotEmpty()) {
            for (pkg in newPkgs) {
                val perms = try {
                    pm.getPackageInfo(pkg, PackageManager.GET_PERMISSIONS)
                        .requestedPermissions?.toList() ?: emptyList()
                } catch (_: Exception) { emptyList() }

                val suspicious = countSuspiciousPerms(perms)
                if (suspicious >= 3) {
                    val name = try { pm.getApplicationLabel(
                        pm.getApplicationInfo(pkg, 0)).toString()
                    } catch (_: Exception) { pkg }
                    showAlert(
                        title = "NUOVA APP SOSPETTA RILEVATA",
                        body = "$name ha $suspicious permissioni sensibili. Controlla in CTOS.",
                        notifId = pkg.hashCode()
                    )
                }
            }
        }
        // Save current package set
        prefs.edit().putString(KEY_KNOWN_PKGS, currentPkgs.joinToString(",")).apply()

        // ── 2. Check for Tor/suspicious TCP connections ────────────
        val torCount = countTorConnections()
        if (torCount > 0) {
            showAlert(
                title = "CONNESSIONI TOR ATTIVE",
                body = "$torCount connessioni a nodi Tor rilevate sul dispositivo.",
                notifId = 7001
            )
        }

        // ── 3. Daily morning briefing (only at 8 AM hour) ─────────
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        if (hour == BRIEFING_HOUR) {
            val riskScore = prefs.getInt(KEY_RISK, 0)
            val vpnActive = prefs.getBoolean(KEY_VPN, false)
            val riskLabel = when {
                riskScore >= 75 -> "CRITICO"
                riskScore >= 50 -> "SOSPETTO"
                riskScore >= 30 -> "MODERATO"
                else            -> "BASSO"
            }
            showAlert(
                title = "CTOS — Briefing mattutino",
                body = "Rischio dispositivo: $riskLabel ($riskScore/100). " +
                       "VPN: ${if (vpnActive) "attiva" else "non attiva"}. " +
                       "App installate: ${currentPkgs.size}.",
                notifId = 8000,
                channelId = CtosProtectionService.PERSISTENT_CHANNEL
            )
        }

        // ── 4. Update last scan time for widget ───────────────────
        val time = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
            .format(java.util.Date())
        prefs.edit().putString(KEY_LAST_SCAN, time).apply()

        // Refresh the widget
        CtosWidget.update(ctx)

        return Result.success()
    }

    private fun countSuspiciousPerms(perms: List<String>): Int {
        val dangerous = setOf(
            "android.permission.CAMERA",
            "android.permission.RECORD_AUDIO",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.READ_CONTACTS",
            "android.permission.READ_CALL_LOG",
            "android.permission.SEND_SMS",
            "android.permission.READ_SMS",
            "android.permission.PROCESS_OUTGOING_CALLS",
            "android.permission.SYSTEM_ALERT_WINDOW",
            "android.permission.BIND_ACCESSIBILITY_SERVICE",
        )
        return perms.count { it in dangerous }
    }

    private fun countTorConnections(): Int {
        val torPrefixes = setOf(
            "185.220.", "199.87.", "195.176.", "51.15.", "45.33.",
            "109.70.", "193.11.", "94.23.", "62.210.", "163.172."
        )
        var count = 0
        try {
            for (f in listOf("/proc/net/tcp", "/proc/net/tcp6")) {
                val file = File(f)
                if (!file.exists()) continue
                for (line in file.readLines().drop(1)) {
                    val parts = line.trim().split("\\s+".toRegex())
                    if (parts.size < 4 || parts[3] != "01") continue
                    val remoteHex = parts[2]
                    val colonIdx = remoteHex.lastIndexOf(':')
                    if (colonIdx < 0) continue
                    val ipHex = remoteHex.substring(0, colonIdx)
                    if (ipHex.length == 8) {
                        val v = ipHex.toLongOrNull(16) ?: continue
                        val ip = "${v and 0xFF}.${(v shr 8) and 0xFF}." +
                                 "${(v shr 16) and 0xFF}.${(v shr 24) and 0xFF}"
                        if (torPrefixes.any { ip.startsWith(it) }) count++
                    }
                }
            }
        } catch (_: Exception) {}
        return count
    }

    private fun showAlert(
        title: String,
        body: String,
        notifId: Int,
        channelId: String = CtosProtectionService.ALERT_CHANNEL
    ) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        val pi = PendingIntent.getActivity(
            ctx, notifId, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notif = NotificationCompat.Builder(ctx, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        nm.notify(notifId, notif)
    }
}
