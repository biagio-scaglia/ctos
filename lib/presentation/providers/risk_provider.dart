import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/risk_level_engine.dart';
import '../../data/local/hive_service.dart';
import 'device_provider.dart';
import 'network_provider.dart';

// ── Current Risk Snapshot ─────────────────────────────────────────────────────

final riskSnapshotProvider = Provider<RiskSnapshot>((ref) {
  final apps = ref.watch(appsProvider).valueOrNull ?? [];
  final connections = ref.watch(connectionsProvider).valueOrNull ?? [];
  final events = HiveService.getEvents(limit: 100);

  return RiskLevelEngine.calculate(
    apps: apps,
    connections: connections,
    recentEvents: events,
  );
});

// ── Risk History ─────────────────────────────────────────────────────────────

class RiskHistoryNotifier extends StateNotifier<List<RiskSnapshot>> {
  RiskHistoryNotifier() : super([]);

  void record(RiskSnapshot snap) {
    final updated = [...state, snap];
    state = updated.length > 168 ? updated.sublist(updated.length - 168) : updated;
  }
}

final riskHistoryProvider =
    StateNotifierProvider<RiskHistoryNotifier, List<RiskSnapshot>>(
  (ref) {
    final notifier = RiskHistoryNotifier();
    ref.listen(riskSnapshotProvider, (_, snap) {
      notifier.record(snap);
    });
    return notifier;
  },
);
