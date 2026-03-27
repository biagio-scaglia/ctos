package com.ctos.companion

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * CTOS home screen widget — shows risk score, VPN status, and last scan time.
 * Data is read from SharedPreferences written by CtosBackgroundWorker and MainActivity.
 */
class CtosWidget : AppWidgetProvider() {

    companion object {
        /** Call this from anywhere to force-refresh all placed widgets. */
        fun update(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, CtosWidget::class.java)
            )
            if (ids.isEmpty()) return
            val intent = Intent(context, CtosWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences(
            CtosBackgroundWorker.PREFS_NAME, Context.MODE_PRIVATE
        )
        val risk      = prefs.getInt(CtosBackgroundWorker.KEY_RISK, 0)
        val vpnActive = prefs.getBoolean(CtosBackgroundWorker.KEY_VPN, false)
        val lastScan  = prefs.getString(CtosBackgroundWorker.KEY_LAST_SCAN, "--:--") ?: "--:--"

        val riskLabel = when {
            risk >= 75 -> "CRITICO"
            risk >= 50 -> "SOSPETTO"
            risk >= 30 -> "VIGILANZA"
            else       -> "SICURO"
        }

        // Tapping the widget opens MainActivity
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val views = RemoteViews(context.packageName, R.layout.widget_ctos).apply {
            setTextViewText(R.id.tv_risk_score, "$risk")
            setTextViewText(R.id.tv_risk_label, riskLabel)
            setTextViewText(R.id.tv_vpn_status, if (vpnActive) "VPN ON" else "NO VPN")
            setTextViewText(R.id.tv_last_scan, "SCAN $lastScan")
            setOnClickPendingIntent(R.id.widget_root, pi)

            // Color risk score: green < 30, amber < 75, red otherwise
            val color = when {
                risk >= 75 -> 0xFFFF1744.toInt()
                risk >= 30 -> 0xFFFFAB00.toInt()
                else       -> 0xFF00E676.toInt()
            }
            setTextColor(R.id.tv_risk_score, color)
            setTextColor(R.id.tv_risk_label, color)

            val vpnColor = if (vpnActive) 0xFF00E5FF.toInt() else 0xFF607D8B.toInt()
            setTextColor(R.id.tv_vpn_status, vpnColor)
        }

        manager.updateAppWidget(widgetId, views)
    }
}
