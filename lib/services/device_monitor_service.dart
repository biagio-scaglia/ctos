import 'dart:async';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/models/app_info.dart';
import '../core/utils/suspicion_calculator.dart';
import '../core/constants.dart';

/// Platform channel for Android-specific APIs
const _channel = MethodChannel('com.ctos.companion/device');

class DeviceInfo {
  final String model;
  final String brand;
  final String androidVersion;
  final int sdkInt;
  final String cpuAbi;
  final int totalRamMb;
  final int availableRamMb;
  final int totalStorageGb;
  final int availableStorageGb;
  final int batteryLevel;
  final bool isCharging;

  const DeviceInfo({
    required this.model,
    required this.brand,
    required this.androidVersion,
    required this.sdkInt,
    required this.cpuAbi,
    required this.totalRamMb,
    required this.availableRamMb,
    required this.totalStorageGb,
    required this.availableStorageGb,
    required this.batteryLevel,
    required this.isCharging,
  });

  int get ramUsedMb => totalRamMb - availableRamMb;
  double get ramUsedPercent =>
      totalRamMb == 0 ? 0 : (ramUsedMb / totalRamMb) * 100;
  double get storageUsedPercent =>
      totalStorageGb == 0 ? 0 : ((totalStorageGb - availableStorageGb) / totalStorageGb) * 100;
}

class DeviceMonitorService {
  static final _battery = Battery();
  static final _deviceInfo = DeviceInfoPlugin();
  static final _rng = Random();

  /// Fetch static device info once
  static Future<DeviceInfo> getDeviceInfo() async {
    final info = await _deviceInfo.androidInfo;
    int batteryLevel = 0;
    bool isCharging = false;

    try {
      batteryLevel = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      isCharging = state == BatteryState.charging || state == BatteryState.full;
    } catch (_) {}

    // Try real RAM from platform channel, fallback to estimate
    int totalRam = 4096, availRam = 2048;
    try {
      final result = await _channel.invokeMethod<Map>('getMemoryInfo');
      totalRam = result?['totalMb'] as int? ?? 4096;
      availRam = result?['availMb'] as int? ?? 2048;
    } catch (_) {
      // Fallback simulated values for demo
      totalRam = 4096;
      availRam = 1800 + _rng.nextInt(800);
    }

    int totalStorage = 64, availStorage = 32;
    try {
      final result = await _channel.invokeMethod<Map>('getStorageInfo');
      totalStorage = result?['totalGb'] as int? ?? 64;
      availStorage = result?['availGb'] as int? ?? 32;
    } catch (_) {
      totalStorage = 64;
      availStorage = 20 + _rng.nextInt(30);
    }

    return DeviceInfo(
      model: info.model,
      brand: info.brand,
      androidVersion: info.version.release,
      sdkInt: info.version.sdkInt,
      cpuAbi: info.supportedAbis.firstOrNull ?? 'arm64-v8a',
      totalRamMb: totalRam,
      availableRamMb: availRam,
      totalStorageGb: totalStorage,
      availableStorageGb: availStorage,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
  }

  /// Fetch installed apps with their permissions and usage stats
  static Future<List<AppInfo>> scanInstalledApps() async {
    List<dynamic> rawApps = [];
    try {
      rawApps = await _channel.invokeMethod<List>('getInstalledApps') ?? [];
    } catch (_) {
      // Fallback: return simulated data for demo/dev
      return _simulatedApps();
    }

    final apps = <AppInfo>[];
    for (final raw in rawApps) {
      final map = Map<String, dynamic>.from(raw as Map);
      final permissions = List<String>.from(map['permissions'] ?? []);
      final cpuUsage = (map['cpuUsage'] as num?)?.toDouble() ?? 0.0;
      final ramMb = (map['ramMb'] as num?)?.toDouble() ?? 0.0;
      final networkMb = (map['networkMb'] as num?)?.toDouble() ?? 0.0;
      final wakeLocks = (map['wakeLocks'] as num?)?.toInt() ?? 0;

      final app = AppInfo(
        packageName: map['packageName'] as String,
        displayName: map['displayName'] as String,
        permissions: permissions,
        cpuUsage: cpuUsage,
        ramUsageMb: ramMb,
        wakeLocksCount: wakeLocks,
        hasAccessibilityService: map['hasAccessibility'] as bool? ?? false,
        startsOnBoot: map['startsOnBoot'] as bool? ?? false,
        networkTrafficMb: networkMb,
        connectsToDatacenter: false,
        suspicionScore: 0,
        lastSeen: DateTime.now(),
        versionName: map['versionName'] as String?,
        isSystemApp: map['isSystem'] as bool? ?? false,
      );

      apps.add(app.copyWith(
        suspicionScore: SuspicionCalculator.calculate(app),
      ));
    }

    return apps;
  }

  static List<AppInfo> _simulatedApps() {
    final rng = Random();
    final sampleApps = [
      ('com.whatsapp', 'WhatsApp', [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.READ_CONTACTS',
        'android.permission.ACCESS_FINE_LOCATION',
      ], false, false),
      ('com.instagram.android', 'Instagram', [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.READ_CONTACTS',
        'android.permission.GET_ACCOUNTS',
      ], false, false),
      ('com.flashlight.pro', 'FlashLight Pro', [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.READ_CONTACTS',
        'android.permission.READ_CALL_LOG',
        'android.permission.SEND_SMS',
      ], true, true),
      ('com.google.android.gms', 'Google Play Services', [
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.GET_ACCOUNTS',
        'android.permission.READ_CONTACTS',
      ], true, false),
      ('com.spotify.music', 'Spotify', [
        'android.permission.RECORD_AUDIO',
      ], false, false),
      ('com.battery.saver.plus', 'Battery Saver+', [
        'android.permission.PACKAGE_USAGE_STATS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.BIND_ACCESSIBILITY_SERVICE',
        'android.permission.WRITE_SETTINGS',
        'android.permission.SYSTEM_ALERT_WINDOW',
      ], false, true),
      ('com.tiktok.android', 'TikTok', [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.READ_CONTACTS',
        'android.permission.GET_ACCOUNTS',
      ], false, false),
      ('com.chrome.browser', 'Chrome', [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.ACCESS_COARSE_LOCATION',
      ], false, false),
    ];

    return sampleApps.map((e) {
      final (pkg, name, perms, boot, accessibility) = e;
      final cpu = rng.nextDouble() * 20;
      final ram = 50 + rng.nextDouble() * 350;
      final net = rng.nextDouble() * 150;
      final wakes = rng.nextInt(5);
      final datacenter = rng.nextBool();

      final app = AppInfo(
        packageName: pkg,
        displayName: name,
        permissions: perms,
        cpuUsage: cpu,
        ramUsageMb: ram,
        wakeLocksCount: wakes,
        hasAccessibilityService: accessibility,
        startsOnBoot: boot,
        networkTrafficMb: net,
        connectsToDatacenter: datacenter,
        suspicionScore: 0,
        lastSeen: DateTime.now(),
        isSystemApp: false,
      );

      return app.copyWith(suspicionScore: SuspicionCalculator.calculate(app));
    }).toList();
  }

  /// Returns true if the PACKAGE_USAGE_STATS permission is granted.
  static Future<bool> hasUsageStatsPermission() async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Settings → Usage Access so the user can grant the permission.
  static Future<void> openUsageSettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  /// Stream battery level every 30 seconds
  static Stream<int> batteryStream() async* {
    while (true) {
      try {
        yield await _battery.batteryLevel;
      } catch (_) {
        yield 80;
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  /// Stream CPU usage (simulated smooth curve for demo)
  static Stream<double> cpuUsageStream() async* {
    final rng = Random();
    double current = 15.0;
    while (true) {
      current = (current + (rng.nextDouble() * 6 - 3)).clamp(5, 85);
      yield current;
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
