import 'dart:async';
import '../data/local/hive_service.dart';
import '../data/models/app_info.dart';
import '../data/models/app_behavior.dart';

class AppBehaviorService {
  static Timer? _timer;

  /// Start recording behavior snapshots every 15 minutes
  static void startTracking(List<AppInfo> Function() getApps) {
    _timer?.cancel();
    _recordSnapshot(getApps());
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      _recordSnapshot(getApps());
    });
  }

  static Future<void> _recordSnapshot(List<AppInfo> apps) async {
    for (final app in apps) {
      final snap = AppBehaviorSnapshot(
        packageName: app.packageName,
        recordedAt: DateTime.now(),
        cpuUsage: app.cpuUsage,
        ramUsageMb: app.ramUsageMb,
        networkTrafficMb: app.networkTrafficMb,
        wakeLocksCount: app.wakeLocksCount,
        suspicionScore: app.suspicionScore,
      );
      await HiveService.saveBehaviorSnapshot(snap);
    }
  }

  static AppBehaviorSummary getSummary(String packageName) {
    final snaps = HiveService.getBehaviorForApp(packageName);
    return AppBehaviorSummary(packageName: packageName, snapshots: snaps);
  }

  /// Returns list of apps whose suspicion score is trending UP significantly
  static List<String> getWorsening(List<AppInfo> allApps) {
    return allApps
        .map((app) => getSummary(app.packageName))
        .where((s) => s.suspicionTrend > 15)
        .map((s) => s.packageName)
        .toList();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
