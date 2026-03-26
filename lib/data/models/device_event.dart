import 'package:hive_flutter/hive_flutter.dart';

part 'device_event.g.dart';

@HiveType(typeId: 2)
enum DeviceEventType {
  @HiveField(0)
  cameraAccess,
  @HiveField(1)
  microphoneAccess,
  @HiveField(2)
  locationAccess,
  @HiveField(3)
  networkSpike,
  @HiveField(4)
  wakeLock,
  @HiveField(5)
  appAutoStart,
  @HiveField(6)
  permissionGranted,
  @HiveField(7)
  permissionRevoked,
  @HiveField(8)
  suspiciousProcess,
  @HiveField(9)
  batteryDrain,
  @HiveField(10)
  vpnDetected,
  @HiveField(11)
  vpnDisconnected,
  @HiveField(12)
  accessibilityEnabled,
  @HiveField(13)
  unusualNetworkConnection,
  @HiveField(14)
  highCpuUsage,
}

@HiveType(typeId: 3)
class DeviceEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final DeviceEventType type;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String? relatedApp;

  @HiveField(5)
  final int severityLevel; // 1-5

  @HiveField(6)
  final Map<String, String>? metadata;

  DeviceEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    this.relatedApp,
    required this.severityLevel,
    this.metadata,
  });

  String get typeLabel => switch (type) {
        DeviceEventType.cameraAccess => 'CAMERA ACCESS',
        DeviceEventType.microphoneAccess => 'MIC ACCESS',
        DeviceEventType.locationAccess => 'LOCATION ACCESS',
        DeviceEventType.networkSpike => 'NETWORK SPIKE',
        DeviceEventType.wakeLock => 'WAKE LOCK',
        DeviceEventType.appAutoStart => 'AUTO START',
        DeviceEventType.permissionGranted => 'PERM GRANTED',
        DeviceEventType.permissionRevoked => 'PERM REVOKED',
        DeviceEventType.suspiciousProcess => 'SUSPICIOUS PROC',
        DeviceEventType.batteryDrain => 'BATTERY DRAIN',
        DeviceEventType.vpnDetected => 'VPN DETECTED',
        DeviceEventType.vpnDisconnected => 'VPN DISCONNECTED',
        DeviceEventType.accessibilityEnabled => 'ACCESSIBILITY ON',
        DeviceEventType.unusualNetworkConnection => 'UNUSUAL CONNECTION',
        DeviceEventType.highCpuUsage => 'HIGH CPU',
      };
}
