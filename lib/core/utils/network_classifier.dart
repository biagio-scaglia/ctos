import '../constants.dart';
import '../../data/models/network_connection.dart';

class NetworkClassifier {
  NetworkClassifier._();

  static int scoreSuspicion(NetworkConnection conn) {
    int score = 0;

    // Known datacenter IP ranges
    if (_isDatacenter(conn.remoteIp)) {
      score += 15;
    }

    // Unusual ports
    if (_isUnusualPort(conn.port)) {
      score += 20;
    }

    // Known VPN/proxy ports
    if (CtosConstants.vpnPorts.contains(conn.port)) {
      score += 15;
    }

    // High traffic on unexpected apps
    if (conn.trafficKbps > 5000) {
      score += 15;
    } else if (conn.trafficKbps > 1000) {
      score += 8;
    }

    // No hostname resolved (bare IP)
    if (conn.hostname.isEmpty || conn.hostname == conn.remoteIp) {
      score += 10;
    }

    // Known Tor exit nodes / anonymizers
    if (_isTorOrAnonymizer(conn.remoteIp)) {
      score += 40;
    }

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
    return CtosConstants.datacenterPrefixes.any((prefix) => ip.startsWith(prefix));
  }

  static bool _isUnusualPort(int port) {
    const commonPorts = {80, 443, 53, 8080, 8443, 3000, 5000};
    return port > 1024 &&
        !commonPorts.contains(port) &&
        !CtosConstants.vpnPorts.contains(port);
  }

  static bool _isTorOrAnonymizer(String ip) {
    // In a real app this would query a Tor exit node list API
    // For demo, we flag known example ranges
    const knownTorPrefixes = ['185.220.', '199.249.', '204.8.'];
    return knownTorPrefixes.any((prefix) => ip.startsWith(prefix));
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
