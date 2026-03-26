import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/device_monitor_service.dart';
import '../../data/local/hive_service.dart';

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
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(ref),
);
