import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import '../data/models/vpn_status.dart';
import '../data/models/device_event.dart';
import '../core/utils/network_classifier.dart';
import 'event_service.dart';

const _channel = MethodChannel('com.ctos.companion/vpn');

class VpnDetectionService {
  static VpnStatus _current = VpnStatus.unknown();
  static final _controller = StreamController<VpnStatus>.broadcast();

  static Stream<VpnStatus> get statusStream => _controller.stream;
  static VpnStatus get current => _current;

  static Future<void> startMonitoring() async {
    // Check immediately, then every 10 seconds
    await _check();
    Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  static Future<void> _check() async {
    final status = await detect();
    final wasActive = _current.isActive;

    _current = status;
    _controller.add(status);

    // Generate events on state changes
    if (!wasActive && status.isActive) {
      await EventService.addEvent(DeviceEvent(
        id: 'vpn_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: DeviceEventType.vpnDetected,
        description: 'VPN connection detected on interface ${status.interfaceName ?? 'unknown'}',
        severityLevel: 3,
        metadata: {
          if (status.serverIp != null) 'server_ip': status.serverIp!,
          if (status.provider != null) 'provider': status.provider!,
          if (status.interfaceName != null) 'interface': status.interfaceName!,
        },
      ));
    } else if (wasActive && !status.isActive) {
      await EventService.addEvent(DeviceEvent(
        id: 'vpn_off_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: DeviceEventType.vpnDisconnected,
        description: 'VPN connection terminated',
        severityLevel: 2,
      ));
    }
  }

  /// Detect VPN using multiple heuristics
  static Future<VpnStatus> detect() async {
    // Method 1: ask Android via platform channel
    try {
      final result = await _channel.invokeMethod<Map>('checkVpn');
      if (result != null) {
        final active = result['active'] as bool? ?? false;
        return VpnStatus(
          state: active ? VpnState.connected : VpnState.disconnected,
          serverIp: result['serverIp'] as String?,
          interfaceName: result['interface'] as String?,
          provider: result['provider'] as String?,
          detectedAt: DateTime.now(),
        );
      }
    } catch (_) {}

    // Method 2: check network interfaces for tun/ppp (Unix)
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.startsWith('tun') ||
            name.startsWith('ppp') ||
            name.startsWith('wg') ||   // WireGuard
            name.startsWith('vpn')) {
          // Found a VPN-like interface
          final serverIp = iface.addresses.isNotEmpty
              ? iface.addresses.first.address
              : null;

          final isDatacenter = serverIp != null &&
              !NetworkClassifier.isPrivateIp(serverIp);

          return VpnStatus(
            state: VpnState.connected,
            serverIp: serverIp,
            interfaceName: iface.name,
            provider: isDatacenter ? 'Cloud-hosted VPN' : null,
            detectedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {}

    return VpnStatus(
      state: VpnState.disconnected,
      detectedAt: DateTime.now(),
    );
  }

  static void dispose() {
    _controller.close();
  }
}

