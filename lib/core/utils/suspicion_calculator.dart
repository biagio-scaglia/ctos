import '../constants.dart';
import '../../data/models/app_info.dart';

class SuspicionCalculator {
  SuspicionCalculator._();

  static int calculate(AppInfo app) {
    int score = 0;

    // 1. Sensitive permissions (max 30)
    int permScore = 0;
    for (final perm in app.permissions) {
      permScore += CtosConstants.permissionWeights[perm] ?? 0;
    }
    score += permScore.clamp(0, 30);

    // 2. Background behaviour (max 25)
    if (app.startsOnBoot) score += 8;
    if (app.hasAccessibilityService) score += 10;
    score += (app.wakeLocksCount * 2).clamp(0, 7);

    // 3. Network traffic anomaly (max 25)
    if (app.networkTrafficMb > 200) { score += 20; }
    else if (app.networkTrafficMb > 100) { score += 12; }
    else if (app.networkTrafficMb > 30) { score += 6; }

    if (app.connectsToDatacenter) { score += 5; }

    // 4. Resource usage (max 20)
    if (app.cpuUsage > 20) { score += 10; }
    else if (app.cpuUsage > 10) { score += 5; }
    else if (app.cpuUsage > 5) { score += 2; }

    if (app.ramUsageMb > 400) { score += 10; }
    else if (app.ramUsageMb > 150) { score += 5; }
    else if (app.ramUsageMb > 50) { score += 2; }

    return score.clamp(0, 100);
  }

  static String label(int score) => switch (score) {
        < 20 => 'CLEAN',
        < 40 => 'LOW',
        < 60 => 'MODERATE',
        < 80 => 'HIGH',
        _ => 'CRITICAL',
      };

  /// Returns the top reasons why this app is flagged.
  static List<String> reasons(AppInfo app) {
    final reasons = <String>[];

    final dangerousPerms = app.permissions
        .where((p) => (CtosConstants.permissionWeights[p] ?? 0) >= 7)
        .map((p) => _permName(p))
        .toList();
    if (dangerousPerms.isNotEmpty) {
      reasons.add('Uses sensitive permissions: ${dangerousPerms.take(3).join(', ')}');
    }

    if (app.hasAccessibilityService) {
      reasons.add('Registered as Accessibility Service (can read screen content)');
    }
    if (app.startsOnBoot) {
      reasons.add('Starts automatically on device boot');
    }
    if (app.wakeLocksCount > 2) {
      reasons.add('Holds ${app.wakeLocksCount} wake locks (prevents device sleep)');
    }
    if (app.networkTrafficMb > 100) {
      reasons.add('High network usage: ${app.networkTrafficMb.toStringAsFixed(1)} MB');
    }
    if (app.connectsToDatacenter) {
      reasons.add('Connects to cloud/datacenter infrastructure in background');
    }
    if (app.cpuUsage > 10) {
      reasons.add('Elevated CPU usage: ${app.cpuUsage.toStringAsFixed(1)}%');
    }

    return reasons;
  }

  static String _permName(String perm) {
    final parts = perm.split('.');
    return parts.last
        .replaceAll('_', ' ')
        .toLowerCase()
        .replaceFirstMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
  }
}
