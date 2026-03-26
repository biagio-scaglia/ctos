import 'package:hive_flutter/hive_flutter.dart';

part 'app_behavior.g.dart';

/// Tracks historical behavior of an app over time for trend analysis
@HiveType(typeId: 4)
class AppBehaviorSnapshot extends HiveObject {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final DateTime recordedAt;

  @HiveField(2)
  final double cpuUsage;

  @HiveField(3)
  final double ramUsageMb;

  @HiveField(4)
  final double networkTrafficMb;

  @HiveField(5)
  final int wakeLocksCount;

  @HiveField(6)
  final int suspicionScore;

  AppBehaviorSnapshot({
    required this.packageName,
    required this.recordedAt,
    required this.cpuUsage,
    required this.ramUsageMb,
    required this.networkTrafficMb,
    required this.wakeLocksCount,
    required this.suspicionScore,
  });
}

/// Aggregated behavior summary for an app
class AppBehaviorSummary {
  final String packageName;
  final List<AppBehaviorSnapshot> snapshots;

  AppBehaviorSummary({
    required this.packageName,
    required this.snapshots,
  });

  double get avgCpu =>
      snapshots.isEmpty ? 0 : snapshots.map((s) => s.cpuUsage).reduce((a, b) => a + b) / snapshots.length;

  double get maxCpu =>
      snapshots.isEmpty ? 0 : snapshots.map((s) => s.cpuUsage).reduce((a, b) => a > b ? a : b);

  double get avgRam =>
      snapshots.isEmpty ? 0 : snapshots.map((s) => s.ramUsageMb).reduce((a, b) => a + b) / snapshots.length;

  double get totalNetwork =>
      snapshots.isEmpty ? 0 : snapshots.map((s) => s.networkTrafficMb).reduce((a, b) => a + b);

  double get avgSuspicion =>
      snapshots.isEmpty ? 0 : snapshots.map((s) => s.suspicionScore.toDouble()).reduce((a, b) => a + b) / snapshots.length;

  /// Score trend: positive = score increasing (worse), negative = improving
  double get suspicionTrend {
    if (snapshots.length < 2) return 0;
    final first = snapshots.first.suspicionScore.toDouble();
    final last = snapshots.last.suspicionScore.toDouble();
    return last - first;
  }

  String get trendLabel {
    final trend = suspicionTrend;
    if (trend > 10) return 'WORSENING';
    if (trend < -10) return 'IMPROVING';
    return 'STABLE';
  }
}
