import 'package:hive_flutter/hive_flutter.dart';

part 'network_connection.g.dart';

@HiveType(typeId: 1)
class NetworkConnection extends HiveObject {
  @HiveField(0)
  final String remoteIp;

  @HiveField(1)
  final String hostname;

  @HiveField(2)
  final int port;

  @HiveField(3)
  final String protocol;

  @HiveField(4)
  final String? country;

  @HiveField(5)
  final String? countryCode;

  @HiveField(6)
  final String? provider;

  @HiveField(7)
  final bool isKnownDatacenter;

  @HiveField(8)
  final double trafficKbps;

  @HiveField(9)
  final int suspicionScore;

  @HiveField(10)
  final List<String> flags;

  @HiveField(11)
  final DateTime firstSeen;

  @HiveField(12)
  final DateTime lastSeen;

  @HiveField(13)
  final String? relatedApp;

  @HiveField(14)
  final double? latitude;

  @HiveField(15)
  final double? longitude;

  NetworkConnection({
    required this.remoteIp,
    required this.hostname,
    required this.port,
    required this.protocol,
    this.country,
    this.countryCode,
    this.provider,
    required this.isKnownDatacenter,
    required this.trafficKbps,
    required this.suspicionScore,
    required this.flags,
    required this.firstSeen,
    required this.lastSeen,
    this.relatedApp,
    this.latitude,
    this.longitude,
  });
}
