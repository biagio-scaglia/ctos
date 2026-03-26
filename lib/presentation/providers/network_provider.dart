import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/network_monitor_service.dart';
import '../../services/vpn_detection_service.dart';
import '../../data/models/network_connection.dart';
import '../../data/models/vpn_status.dart';

// ── Live Connections Stream ───────────────────────────────────────────────────

final connectionsProvider = StreamProvider<List<NetworkConnection>>((ref) {
  return NetworkMonitorService.connectionsStream();
});

// ── Traffic Stream (kbps) ─────────────────────────────────────────────────────

final trafficProvider = StreamProvider<double>((ref) {
  return NetworkMonitorService.trafficStream();
});

// ── VPN Status ────────────────────────────────────────────────────────────────

final vpnStatusProvider = StreamProvider<VpnStatus>((ref) {
  VpnDetectionService.startMonitoring();
  return VpnDetectionService.statusStream;
});

// ── Traffic History (for sparkline) ──────────────────────────────────────────

class TrafficHistoryNotifier extends StateNotifier<List<double>> {
  TrafficHistoryNotifier() : super([]);

  void add(double value) {
    final updated = [...state, value];
    // Keep last 60 samples
    state = updated.length > 60 ? updated.sublist(updated.length - 60) : updated;
  }
}

final trafficHistoryProvider =
    StateNotifierProvider<TrafficHistoryNotifier, List<double>>(
  (ref) {
    final notifier = TrafficHistoryNotifier();
    ref.listen(trafficProvider, (_, next) {
      next.whenData(notifier.add);
    });
    return notifier;
  },
);

// ── Suspicious connections count ──────────────────────────────────────────────

final suspiciousConnectionsCountProvider = Provider<int>((ref) {
  return ref.watch(connectionsProvider).whenOrNull(
        data: (conns) => conns.where((c) => c.suspicionScore > 50).length,
      ) ?? 0;
});
