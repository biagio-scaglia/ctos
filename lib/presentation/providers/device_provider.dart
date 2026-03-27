import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/device_monitor_service.dart';
import '../../services/security_guardian_service.dart';
import '../../data/local/hive_service.dart';
import 'network_provider.dart';
import 'risk_provider.dart';

// ── Device Info ──────────────────────────────────────────────────────────────

final deviceInfoProvider = FutureProvider<DeviceInfo>((ref) async {
  return DeviceMonitorService.getDeviceInfo();
});

// ── Battery ───────────────────────────────────────────────────────────────────

final batteryProvider = StreamProvider<int>((ref) {
  return DeviceMonitorService.batteryStream();
});

// ── CPU Usage ─────────────────────────────────────────────────────────────────

final cpuUsageProvider = StreamProvider<double>((ref) {
  return DeviceMonitorService.cpuUsageStream();
});

// ── Usage Stats Permission ────────────────────────────────────────────────────

final usageStatsGrantedProvider = FutureProvider<bool>((ref) async {
  return DeviceMonitorService.hasUsageStatsPermission();
});

// ── Installed Apps ────────────────────────────────────────────────────────────

final appsProvider = FutureProvider((ref) async {
  final cached = HiveService.getAllApps();
  if (cached.isNotEmpty) return cached;
  final apps = await DeviceMonitorService.scanInstalledApps();
  await HiveService.saveAllApps(apps);
  return apps;
});

// ── Scan State ────────────────────────────────────────────────────────────────

class ScanState {
  final bool isScanning;
  final double progress;
  final int appsScanned;
  final int totalApps;

  const ScanState({
    this.isScanning = false,
    this.progress = 0,
    this.appsScanned = 0,
    this.totalApps = 0,
  });

  ScanState copyWith({
    bool? isScanning,
    double? progress,
    int? appsScanned,
    int? totalApps,
  }) =>
      ScanState(
        isScanning: isScanning ?? this.isScanning,
        progress: progress ?? this.progress,
        appsScanned: appsScanned ?? this.appsScanned,
        totalApps: totalApps ?? this.totalApps,
      );
}

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;
  ScanNotifier(this._ref) : super(const ScanState());

  Future<void> startScan() async {
    state = state.copyWith(isScanning: true, progress: 0, appsScanned: 0);

    // Simulate progressive scan
    final apps = await DeviceMonitorService.scanInstalledApps();
    await HiveService.saveAllApps(apps);

    for (int i = 0; i < apps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(
        appsScanned: i + 1,
        totalApps: apps.length,
        progress: (i + 1) / apps.length,
      );
    }

    state = state.copyWith(isScanning: false, progress: 1.0);
    _ref.invalidate(appsProvider);

    // Start (or keep alive) the real-time guardian now that we have fresh data
    SecurityGuardianService.start(
      getApps: () => _ref.read(appsProvider).valueOrNull ?? [],
      getConnections: () => _ref.read(connectionsProvider).valueOrNull ?? [],
    );

    // Update widget with latest risk data
    _updateWidget();
  }

  void _updateWidget() {
    if (kIsWeb) return;
    final risk = _ref.read(riskSnapshotProvider);
    final vpn  = _ref.read(vpnStatusProvider).valueOrNull?.isActive ?? false;
    final time = '${DateTime.now().hour.toString().padLeft(2, '0')}:'
                 '${DateTime.now().minute.toString().padLeft(2, '0')}';
    const channel = MethodChannel('com.ctos.companion/device');
    channel.invokeMethod('updateWidgetData', {
      'riskScore': risk.totalScore,
      'vpnActive': vpn,
      'lastScan': time,
    }).ignore();
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(ref),
);
