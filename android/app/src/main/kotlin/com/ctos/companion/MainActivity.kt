package com.ctos.companion

import android.app.ActivityManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val DEVICE_CHANNEL = "com.ctos.companion/device"
    private val VPN_CHANNEL = "com.ctos.companion/vpn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Device info channel ───────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMemoryInfo" -> result.success(getMemoryInfo())
                    "getStorageInfo" -> result.success(getStorageInfo())
                    "getInstalledApps" -> result.success(getInstalledAppsInfo())
                    else -> result.notImplemented()
                }
            }

        // ── VPN detection channel ─────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkVpn" -> result.success(checkVpn())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getMemoryInfo(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)
        return mapOf(
            "totalMb" to (memInfo.totalMem / (1024 * 1024)).toInt(),
            "availMb" to (memInfo.availMem / (1024 * 1024)).toInt()
        )
    }

    private fun getStorageInfo(): Map<String, Any> {
        return try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val blockSize = stat.blockSizeLong
            val total = (stat.blockCountLong * blockSize) / (1024 * 1024 * 1024)
            val avail = (stat.availableBlocksLong * blockSize) / (1024 * 1024 * 1024)
            mapOf("totalGb" to total.toInt(), "availGb" to avail.toInt())
        } catch (e: Exception) {
            mapOf("totalGb" to 64, "availGb" to 32)
        }
    }

    private fun getInstalledAppsInfo(): List<Map<String, Any>> {
        // NOTE: Full implementation requires PACKAGE_USAGE_STATS permission
        // and usage stats manager. Returning basic info for demo.
        val pm = packageManager
        val apps = pm.getInstalledApplications(0)
        return apps.take(30).mapNotNull { appInfo ->
            try {
                val appName = pm.getApplicationLabel(appInfo).toString()
                val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                val perms = try {
                    pm.getPackageInfo(appInfo.packageName,
                        android.content.pm.PackageManager.GET_PERMISSIONS)
                        .requestedPermissions?.toList() ?: emptyList()
                } catch (e: Exception) { emptyList<String>() }

                mapOf<String, Any>(
                    "packageName" to appInfo.packageName,
                    "displayName" to appName,
                    "permissions" to perms,
                    "cpuUsage" to 0.0,
                    "ramMb" to 0.0,
                    "networkMb" to 0.0,
                    "wakeLocks" to 0,
                    "hasAccessibility" to false,
                    "startsOnBoot" to false,
                    "isSystem" to isSystem,
                    "versionName" to (pm.getPackageInfo(appInfo.packageName, 0).versionName ?: "")
                )
            } catch (e: Exception) { null }
        }
    }

    private fun checkVpn(): Map<String, Any?> {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return mapOf("active" to false)
        val caps = cm.getNetworkCapabilities(network) ?: return mapOf("active" to false)
        val isVpn = caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        return mapOf(
            "active" to isVpn,
            "interface" to if (isVpn) "vpn0" else null,
            "serverIp" to null,
            "provider" to null
        )
    }
}
