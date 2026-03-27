import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../data/models/network_connection.dart';
import '../core/utils/network_classifier.dart';
import '../core/constants.dart';

class NetworkMonitorService {
  static final _rng = Random();
  static final _geoCache = <String, Map<String, dynamic>>{};

  /// Real external IP of the device (fetched once from ipify.org)
  static String? realExternalIp;

  /// Initialise: load Tor exit list + fetch own external IP
  static Future<void> init() async {
    await Future.wait([
      NetworkClassifier.loadTorExitNodes(),
      _fetchExternalIp(),
    ]);
  }

  static Future<void> _fetchExternalIp() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.ipify.org'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final ip = res.body.trim();
        if (ip.isNotEmpty) realExternalIp = ip;
      }
    } catch (_) {}
  }

  /// Live stream of active connections, refreshed every 2 seconds
  static Stream<List<NetworkConnection>> connectionsStream() async* {
    while (true) {
      yield await getCurrentConnections();
      await Future.delayed(CtosConstants.networkRefresh);
    }
  }

  /// Stream of total traffic (kbps) for the sparkline graph
  static Stream<double> trafficStream() async* {
    while (true) {
      double kbps = 50 + _rng.nextDouble() * 800;
      if (_rng.nextInt(10) == 0) kbps += 2000 + _rng.nextDouble() * 3000;
      yield kbps;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  static Future<List<NetworkConnection>> getCurrentConnections() async {
    return _simulatedConnections();
  }

  static Future<Map<String, dynamic>?> geolocateIp(String ip) async {
    if (NetworkClassifier.isPrivateIp(ip)) return null;
    if (_geoCache.containsKey(ip)) return _geoCache[ip];

    try {
      final response = await http
          .get(Uri.parse('${CtosConstants.geoIpApi}$ip'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          _geoCache[ip] = data;
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  static List<NetworkConnection> _simulatedConnections() {
    final baseConns = [
      ('142.250.184.46', 'google.com', 443, 'HTTPS', 'United States', 'US', 'Google LLC', true, 320.0),
      ('31.13.86.36', 'edge-star-mini-shv-01.facebook.com', 443, 'HTTPS', 'United States', 'US', 'Meta Platforms', true, 89.0),
      ('52.84.49.15', 'cloudfront.net', 443, 'HTTPS', 'United States', 'US', 'Amazon CloudFront', true, 540.0),
      ('185.220.101.47', '', 9001, 'TCP', 'Germany', 'DE', 'Tor Exit Node', false, 12.0),
      ('185.199.108.153', 'github.githubassets.com', 443, 'HTTPS', 'United States', 'US', 'GitHub', true, 201.0),
      ('193.32.83.12', '', 8080, 'HTTP', 'Netherlands', 'NL', 'Unknown Hosting', false, 44.0),
      ('151.101.1.195', 'reddit.com', 443, 'HTTPS', 'United States', 'US', 'Fastly', true, 155.0),
      ('104.16.99.52', 'workers.dev', 443, 'HTTPS', 'United States', 'US', 'Cloudflare', true, 77.0),
    ];

    return baseConns.asMap().entries.map((entry) {
      final (ip, host, port, proto, country, cc, provider, isdc, traffic) =
          entry.value;

      final noise = _rng.nextDouble() * 50 - 25;
      final adjustedTraffic = (traffic + noise).clamp(0.0, double.infinity);

      final conn = NetworkConnection(
        remoteIp: ip,
        hostname: host,
        port: port,
        protocol: proto,
        country: country,
        countryCode: cc,
        provider: provider,
        isKnownDatacenter: isdc,
        trafficKbps: adjustedTraffic,
        suspicionScore: 0,
        flags: [],
        firstSeen: DateTime.now().subtract(Duration(minutes: _rng.nextInt(60))),
        lastSeen: DateTime.now(),
      );

      final score = NetworkClassifier.scoreSuspicion(conn);
      final flags = NetworkClassifier.flags(conn);

      return NetworkConnection(
        remoteIp: conn.remoteIp,
        hostname: conn.hostname,
        port: conn.port,
        protocol: conn.protocol,
        country: conn.country,
        countryCode: conn.countryCode,
        provider: conn.provider,
        isKnownDatacenter: conn.isKnownDatacenter,
        trafficKbps: conn.trafficKbps,
        suspicionScore: score,
        flags: flags,
        firstSeen: conn.firstSeen,
        lastSeen: conn.lastSeen,
      );
    }).toList();
  }
}
