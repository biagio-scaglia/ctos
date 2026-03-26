import '../../data/models/app_info.dart';
import '../../data/models/device_event.dart';
import '../../data/models/network_connection.dart';

enum RiskLevel { safe, low, moderate, high, critical }

class RiskSnapshot {
  final int totalScore;
  final int appRisk;
  final int networkRisk;
  final int eventRisk;
  final RiskLevel level;
  final DateTime calculatedAt;

  const RiskSnapshot({
    required this.totalScore,
    required this.appRisk,
    required this.networkRisk,
    required this.eventRisk,
    required this.level,
    required this.calculatedAt,
  });
}

class RiskLevelEngine {
  RiskLevelEngine._();

  static RiskSnapshot calculate({
    required List<AppInfo> apps,
    required List<NetworkConnection> connections,
    required List<DeviceEvent> recentEvents,
  }) {
    // App risk: weighted average of top 5 suspicious apps (50%)
    final sortedScores = apps.map((a) => a.suspicionScore).toList()
      ..sort((a, b) => b.compareTo(a));
    final top5 = sortedScores.take(5).toList();
    final appRaw = top5.isEmpty
        ? 0
        : top5.fold(0, (s, v) => s + v) ~/ top5.length;
    final appRisk = (appRaw * 0.5).round().clamp(0, 50);

    // Network risk: 5 pts per suspicious connection, capped at 30 (30%)
    final suspiciousConns =
        connections.where((c) => c.suspicionScore > 50).length;
    final networkRisk = (suspiciousConns * 5).clamp(0, 30);

    // Event risk: severity-weighted events in last 24h (20%)
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final recentCritical = recentEvents
        .where((e) => e.timestamp.isAfter(cutoff) && e.severityLevel >= 4)
        .length;
    final recentHigh = recentEvents
        .where((e) =>
            e.timestamp.isAfter(cutoff) &&
            e.severityLevel == 3 &&
            e.severityLevel < 4)
        .length;
    final eventRisk = (recentCritical * 5 + recentHigh * 2).clamp(0, 20);

    final total = (appRisk + networkRisk + eventRisk).clamp(0, 100);

    return RiskSnapshot(
      totalScore: total,
      appRisk: appRisk,
      networkRisk: networkRisk,
      eventRisk: eventRisk,
      level: _toLevel(total),
      calculatedAt: DateTime.now(),
    );
  }

  static RiskLevel _toLevel(int score) => switch (score) {
        < 20 => RiskLevel.safe,
        < 40 => RiskLevel.low,
        < 60 => RiskLevel.moderate,
        < 80 => RiskLevel.high,
        _ => RiskLevel.critical,
      };

  static String levelLabel(RiskLevel level) => switch (level) {
        RiskLevel.safe => 'SECURE',
        RiskLevel.low => 'LOW RISK',
        RiskLevel.moderate => 'MODERATE',
        RiskLevel.high => 'HIGH RISK',
        RiskLevel.critical => 'CRITICAL',
      };
}
