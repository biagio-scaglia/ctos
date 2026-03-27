import 'dart:async';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../../data/models/network_connection.dart';

class NetworkClassifier {
  NetworkClassifier._();

  // Real Tor exit nodes fetched from torproject.org
  static Set<String> _torExitNodes = {};
  static DateTime? _torFetchedAt;

  /// Fetch the live Tor exit node list (no API key needed).
  /// Cached for 1 hour. Call once at startup from NetworkMonitorService.
  static Future<void> loadTorExitNodes() async {
    final now = DateTime.now();
    if (_torFetchedAt != null &&
        now.difference(_torFetchedAt!) < const Duration(hours: 1)) {
      return; // still fresh
    }
    try {
      final response = await http
          .get(Uri.parse('https://check.torproject.org/torbulkexitlist'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        _torExitNodes = response.body
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && !l.startsWith('#'))
            .toSet();
        _torFetchedAt = now;
      }
    } catch (_) {
      // Fall back to known prefixes (see _isTorOrAnonymizer)
    }
  }

  static int scoreSuspicion(NetworkConnection conn) {
    int score = 0;

    if (_isDatacenter(conn.remoteIp)) score += 15;
    if (_isUnusualPort(conn.port)) score += 20;
    if (CtosConstants.vpnPorts.contains(conn.port)) score += 15;

    if (conn.trafficKbps > 5000) {
      score += 15;
    } else if (conn.trafficKbps > 1000) {
      score += 8;
    }

    if (conn.hostname.isEmpty || conn.hostname == conn.remoteIp) score += 10;
    if (_isTorOrAnonymizer(conn.remoteIp)) score += 40;

    return score.clamp(0, 100);
  }

  static List<String> flags(NetworkConnection conn) {
    final flags = <String>[];
    if (_isDatacenter(conn.remoteIp)) flags.add('DATACENTER');
    if (CtosConstants.vpnPorts.contains(conn.port)) flags.add('VPN_PORT');
    if (_isUnusualPort(conn.port)) flags.add('UNUSUAL_PORT');
    if (_isTorOrAnonymizer(conn.remoteIp)) flags.add('TOR/ANON');
    if (conn.hostname.isEmpty || conn.hostname == conn.remoteIp) {
      flags.add('NO_HOSTNAME');
    }
    if (conn.trafficKbps > 5000) flags.add('HIGH_TRAFFIC');
    return flags;
  }

  static bool _isDatacenter(String ip) {
    return CtosConstants.datacenterPrefixes.any((p) => ip.startsWith(p));
  }

  static bool _isUnusualPort(int port) {
    const commonPorts = {80, 443, 53, 8080, 8443, 3000, 5000};
    return port > 1024 &&
        !commonPorts.contains(port) &&
        !CtosConstants.vpnPorts.contains(port);
  }

  static bool _isTorOrAnonymizer(String ip) {
    // Use live list when available
    if (_torExitNodes.isNotEmpty) return _torExitNodes.contains(ip);
    // Fallback: well-known Tor exit prefixes
    const fallbackPrefixes = ['185.220.', '199.249.', '204.8.', '171.25.'];
    return fallbackPrefixes.any((p) => ip.startsWith(p));
  }

  static bool isPrivateIp(String ip) {
    return ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        ip.startsWith('172.16.') ||
        ip.startsWith('172.17.') ||
        ip.startsWith('172.18.') ||
        ip.startsWith('172.19.') ||
        ip.startsWith('172.2') ||
        ip.startsWith('172.30.') ||
        ip.startsWith('172.31.') ||
        ip == '127.0.0.1' ||
        ip == '::1';
  }
}
