package com.ctos.companion

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.view.accessibility.AccessibilityManager
import android.view.accessibility.AccessibilityServiceInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val DEVICE_CHANNEL   = "com.ctos.companion/device"
    private val VPN_CHANNEL      = "com.ctos.companion/vpn"
    private val GUARDIAN_CHANNEL = "com.ctos.companion/guardian"

    // Shared URL from external apps (e.g. Chrome → Share → CTOS)
    private var pendingSharedUrl: String? = null
    private var guardianChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMemoryInfo"         -> result.success(getMemoryInfo())
                    "getStorageInfo"        -> result.success(getStorageInfo())
                    "getInstalledApps"      -> result.success(getInstalledAppsInfo())
                    "getNetworkConnections" -> result.success(getNetworkConnections())
                    else                    -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkVpn" -> result.success(checkVpn())
                    else       -> result.notImplemented()
                }
            }

        guardianChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GUARDIAN_CHANNEL)
        guardianChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "startProtection" -> {
                    CtosProtectionService.start(this)
                    result.success(true)
                }
                "stopProtection" -> {
                    CtosProtectionService.stop(this)
                    result.success(true)
                }
                "showAlert" -> {
                    val title = call.argument<String>("title") ?: "CTOS Alert"
                    val body  = call.argument<String>("body")  ?: ""
                    val level = call.argument<Int>("level")    ?: 3
                    CtosProtectionService.showAlert(this, title, body, level)
                    result.success(true)
                }
                "getSharedUrl" -> {
                    result.success(pendingSharedUrl)
                    pendingSharedUrl = null
                }
                else -> result.notImplemented()
            }
        }

        // Start protection service immediately when Flutter engine is ready
        CtosProtectionService.start(this)

        // Deliver any URL that was shared to CTOS before the engine was ready
        extractSharedUrl(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        extractSharedUrl(intent)
        // Notify Flutter about the new URL
        pendingSharedUrl?.let { url ->
            guardianChannel?.invokeMethod("onSharedUrl", url)
        }
    }

    private fun extractSharedUrl(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND &&
            intent.type?.startsWith("text/") == true) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
            // Extract URL from shared text (may contain surrounding context)
            val urlRegex = Regex("https?://[^\\s]+")
            val found = urlRegex.find(text)?.value
            if (found != null) pendingSharedUrl = found
            else if (text.startsWith("http")) pendingSharedUrl = text.trim()
        }
    }

    // ─── Memory ────────────────────────────────────────────────────────────────

    private fun getMemoryInfo(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mem)
        return mapOf(
            "totalMb" to (mem.totalMem / (1024 * 1024)).toInt(),
            "availMb" to (mem.availMem  / (1024 * 1024)).toInt()
        )
    }

    // ─── Storage ───────────────────────────────────────────────────────────────

    private fun getStorageInfo(): Map<String, Any> = try {
        val stat = StatFs(Environment.getDataDirectory().path)
        val bs   = stat.blockSizeLong
        mapOf(
            "totalGb" to (stat.blockCountLong * bs / (1024 * 1024 * 1024)).toInt(),
            "availGb" to (stat.availableBlocksLong * bs / (1024 * 1024 * 1024)).toInt()
        )
    } catch (e: Exception) { mapOf("totalGb" to 64, "availGb" to 32) }

    // ─── Installed apps (real data) ────────────────────────────────────────────

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getInstalledAppsInfo(): List<Map<String, Any>> {
        val pm  = packageManager
        val am  = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val a11y = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val hasStats = hasUsageStatsPermission()

        // ── Accessibility: which packages have a service enabled ──────────────
        val enabledA11y = a11y
            .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .mapNotNull { it.resolveInfo?.serviceInfo?.packageName }
            .toSet()

        // ── Boot receivers ────────────────────────────────────────────────────
        val bootPackages = pm
            .queryBroadcastReceivers(Intent(Intent.ACTION_BOOT_COMPLETED), 0)
            .mapNotNull { it.activityInfo?.packageName }
            .toSet()

        // ── Running processes → RAM via PSS ───────────────────────────────────
        val runningProcs = am.runningAppProcesses ?: emptyList()
        val pidsByPkg    = mutableMapOf<String, Int>()
        for (proc in runningProcs)
            for (pkg in proc.pkgList ?: emptyArray()) pidsByPkg[pkg] = proc.pid

        val pids    = runningProcs.map { it.pid }.toIntArray()
        val memInfo = if (pids.isNotEmpty()) am.getProcessMemoryInfo(pids) else emptyArray()
        val ramByPid = mutableMapOf<Int, Long>()
        pids.forEachIndexed { i, pid -> ramByPid[pid] = memInfo.getOrNull(i)?.totalPss?.toLong() ?: 0L }

        // ── UsageStats & NetworkStats (need PACKAGE_USAGE_STATS permission) ────
        val now       = System.currentTimeMillis()
        val yesterday = now - 24L * 60 * 60 * 1000

        val usageByPkg: Map<String, Long> = if (hasStats) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, yesterday, now)
                ?.associate { it.packageName to it.totalTimeInForeground } ?: emptyMap()
        } else emptyMap()

        val netMbByUid: Map<Int, Double> = if (hasStats && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            buildNetworkMbMap(yesterday, now)
        } else emptyMap()

        // ── All user-installed apps (+ flagged system apps) ───────────────────
        val allApps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }

        return allApps.mapNotNull { appInfo ->
            try {
                val perms = try {
                    pm.getPackageInfo(appInfo.packageName, PackageManager.GET_PERMISSIONS)
                        .requestedPermissions?.toList() ?: emptyList()
                } catch (e: Exception) { emptyList<String>() }

                val pid     = pidsByPkg[appInfo.packageName]
                val ramMb   = ((ramByPid[pid] ?: 0L) / 1024.0)          // PSS KB → MB
                val cpuPct  = if (pid != null) readCpuPercent(pid) else 0.0
                val netMb   = netMbByUid[appInfo.uid] ?: 0.0
                val usageSec= (usageByPkg[appInfo.packageName] ?: 0L) / 1000.0

                mapOf<String, Any>(
                    "packageName"    to appInfo.packageName,
                    "displayName"    to (pm.getApplicationLabel(appInfo).toString()),
                    "permissions"    to perms,
                    "cpuUsage"       to cpuPct,
                    "ramMb"          to ramMb,
                    "networkMb"      to netMb,
                    "wakeLocks"      to 0,
                    "hasAccessibility" to (appInfo.packageName in enabledA11y),
                    "startsOnBoot"   to (appInfo.packageName in bootPackages),
                    "isSystem"       to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                    "versionName"    to (try { pm.getPackageInfo(appInfo.packageName, 0).versionName ?: "" } catch (e: Exception) { "" }),
                    "foregroundSec"  to usageSec
                )
            } catch (e: Exception) { null }
        }
    }

    /** Read current CPU% for a PID via /proc/[pid]/stat */
    private fun readCpuPercent(pid: Int): Double = try {
        val stat   = File("/proc/$pid/stat").readText().trim().split(" ")
        val utime  = stat[13].toLong()
        val stime  = stat[14].toLong()
        val total  = utime + stime                               // clock ticks

        // Uptime in seconds
        val uptime = File("/proc/uptime").readText().trim().split(" ")[0].toDouble()
        val clkHz  = 100.0   // standard Linux HZ

        val cpuPct = (total / clkHz) / uptime * 100.0
        cpuPct.coerceIn(0.0, 100.0)
    } catch (e: Exception) { 0.0 }

    /** Build UID→networkMb map from NetworkStatsManager */
    private fun buildNetworkMbMap(startMs: Long, endMs: Long): Map<Int, Double> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptyMap()
        return try {
            val nsm = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
            val cm  = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val result = mutableMapOf<Int, Double>()

            for (type in listOf(ConnectivityManager.TYPE_WIFI, ConnectivityManager.TYPE_MOBILE)) {
                try {
                    val subscriberId = if (type == ConnectivityManager.TYPE_MOBILE) {
                        // Pass empty string — works without READ_PHONE_STATE on many builds
                        ""
                    } else null

                    val bucket = nsm.querySummary(type, subscriberId, startMs, endMs)
                    val b = android.app.usage.NetworkStats.Bucket()
                    while (bucket.hasNextBucket()) {
                        bucket.getNextBucket(b)
                        val uid = b.uid
                        if (uid > 0) {
                            val mb = (b.rxBytes + b.txBytes) / (1024.0 * 1024.0)
                            result[uid] = (result[uid] ?: 0.0) + mb
                        }
                    }
                    bucket.close()
                } catch (e: Exception) { /* permission denied for this type */ }
            }
            result
        } catch (e: Exception) { emptyMap() }
    }

    // ─── Real network connections from /proc/net/tcp ───────────────────────────

    private fun getNetworkConnections(): List<Map<String, Any?>> {
        val pm          = packageManager
        val connections = mutableListOf<Map<String, Any?>>()

        for ((fileName, proto, isV6) in listOf(
            Triple("tcp",  "TCP", false),
            Triple("tcp6", "TCP", true),
            Triple("udp",  "UDP", false),
            Triple("udp6", "UDP", true)
        )) {
            try {
                val file = File("/proc/net/$fileName")
                if (!file.exists() || !file.canRead()) continue

                for (line in file.readLines().drop(1)) {
                    val parts = line.trim().split("\\s+".toRegex())
                    if (parts.size < 12) continue

                    val state      = parts[3]
                    val remoteHex  = parts[2]
                    val uid        = parts[7].toIntOrNull() ?: continue

                    // For TCP keep only ESTABLISHED (01); UDP has no "state"
                    if (proto == "TCP" && state != "01") continue

                    val colonIdx   = remoteHex.lastIndexOf(':')
                    if (colonIdx < 0) continue
                    val ipHex      = remoteHex.substring(0, colonIdx)
                    val portHex    = remoteHex.substring(colonIdx + 1)

                    val remoteIp   = parseHexIp(ipHex, isV6) ?: continue
                    val remotePort = portHex.toIntOrNull(16) ?: continue

                    // Skip loopback and wildcard
                    if (remoteIp == "0.0.0.0" || remoteIp == "::" ||
                        remoteIp.startsWith("127.") || remoteIp == "::1") continue
                    if (remotePort == 0) continue

                    val packages = try {
                        pm.getPackagesForUid(uid)?.toList() ?: emptyList()
                    } catch (e: Exception) { emptyList<String>() }

                    connections.add(mapOf(
                        "remoteIp"   to remoteIp,
                        "remotePort" to remotePort,
                        "protocol"   to proto,
                        "uid"        to uid,
                        "packages"   to packages,
                        "state"      to state
                    ))
                }
            } catch (e: Exception) { /* /proc not readable on this build */ }
        }

        // Deduplicate by remoteIp:remotePort, keep highest-uid entry
        return connections
            .groupBy { "${it["remoteIp"]}:${it["remotePort"]}" }
            .values
            .map { group -> group.maxByOrNull { (it["uid"] as? Int) ?: 0 }!! }
            .sortedByDescending { (it["remotePort"] as? Int) ?: 0 }
    }

    /** Parse a hex IP string (4 bytes IPv4 or 16 bytes IPv6) from /proc/net/tcp */
    private fun parseHexIp(hex: String, isV6: Boolean): String? = try {
        if (isV6) {
            if (hex.length != 32) return null
            // 4 groups of 8 hex chars, each group is a 32-bit LE word
            val words = (0 until 4).map { g ->
                val word = hex.substring(g * 8, g * 8 + 8).toLong(16)
                // Reverse bytes within each 32-bit word
                val b0 = (word shr 24) and 0xFF
                val b1 = (word shr 16) and 0xFF
                val b2 = (word shr 8 ) and 0xFF
                val b3 =  word         and 0xFF
                (b3 shl 24) or (b2 shl 16) or (b1 shl 8) or b0
            }
            // Format as IPv6 groups of 16 bits each
            val groups = mutableListOf<String>()
            for (w in words) {
                groups.add(String.format("%x", (w shr 16) and 0xFFFF))
                groups.add(String.format("%x",  w         and 0xFFFF))
            }
            groups.joinToString(":")
        } else {
            if (hex.length != 8) return null
            val v = hex.toLong(16)
            // Little-endian: byte0 is least significant
            "${v and 0xFF}.${(v shr 8) and 0xFF}.${(v shr 16) and 0xFF}.${(v shr 24) and 0xFF}"
        }
    } catch (e: Exception) { null }

    // ─── VPN detection ─────────────────────────────────────────────────────────

    private fun checkVpn(): Map<String, Any?> {
        val cm      = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return mapOf("active" to false)
        val caps    = cm.getNetworkCapabilities(network) ?: return mapOf("active" to false)
        val isVpn   = caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        return mapOf(
            "active"    to isVpn,
            "interface" to if (isVpn) "vpn0" else null,
            "serverIp"  to null,
            "provider"  to null
        )
    }
}
