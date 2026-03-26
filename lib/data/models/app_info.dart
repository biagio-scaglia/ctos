import 'package:hive_flutter/hive_flutter.dart';

part 'app_info.g.dart';

@HiveType(typeId: 0)
class AppInfo extends HiveObject {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String? iconBase64;

  @HiveField(3)
  final List<String> permissions;

  @HiveField(4)
  final double cpuUsage;

  @HiveField(5)
  final double ramUsageMb;

  @HiveField(6)
  final int wakeLocksCount;

  @HiveField(7)
  final bool hasAccessibilityService;

  @HiveField(8)
  final bool startsOnBoot;

  @HiveField(9)
  final double networkTrafficMb;

  @HiveField(10)
  final bool connectsToDatacenter;

  @HiveField(11)
  final int suspicionScore;

  @HiveField(12)
  final DateTime lastSeen;

  @HiveField(13)
  final String? versionName;

  @HiveField(14)
  final bool isSystemApp;

  AppInfo({
    required this.packageName,
    required this.displayName,
    this.iconBase64,
    required this.permissions,
    required this.cpuUsage,
    required this.ramUsageMb,
    required this.wakeLocksCount,
    required this.hasAccessibilityService,
    required this.startsOnBoot,
    required this.networkTrafficMb,
    required this.connectsToDatacenter,
    required this.suspicionScore,
    required this.lastSeen,
    this.versionName,
    required this.isSystemApp,
  });

  AppInfo copyWith({
    int? suspicionScore,
    double? cpuUsage,
    double? ramUsageMb,
    double? networkTrafficMb,
    int? wakeLocksCount,
    bool? connectsToDatacenter,
    DateTime? lastSeen,
  }) {
    return AppInfo(
      packageName: packageName,
      displayName: displayName,
      iconBase64: iconBase64,
      permissions: permissions,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      ramUsageMb: ramUsageMb ?? this.ramUsageMb,
      wakeLocksCount: wakeLocksCount ?? this.wakeLocksCount,
      hasAccessibilityService: hasAccessibilityService,
      startsOnBoot: startsOnBoot,
      networkTrafficMb: networkTrafficMb ?? this.networkTrafficMb,
      connectsToDatacenter: connectsToDatacenter ?? this.connectsToDatacenter,
      suspicionScore: suspicionScore ?? this.suspicionScore,
      lastSeen: lastSeen ?? this.lastSeen,
      versionName: versionName,
      isSystemApp: isSystemApp,
    );
  }
}
