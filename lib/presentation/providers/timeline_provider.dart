import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device_event.dart';
import '../../services/event_service.dart';

// ── Event filter ──────────────────────────────────────────────────────────────

final eventTypeFilterProvider =
    StateProvider<DeviceEventType?>((ref) => null);

// ── Timeline events ───────────────────────────────────────────────────────────

final timelineProvider = StreamProvider<List<DeviceEvent>>((ref) async* {
  // Yield initial state
  yield EventService.getRecent(limit: 200);

  // Then yield on every new event
  await for (final _ in EventService.stream) {
    yield EventService.getRecent(limit: 200);
  }
});

// ── Filtered timeline ─────────────────────────────────────────────────────────

final filteredTimelineProvider = Provider<List<DeviceEvent>>((ref) {
  final events = ref.watch(timelineProvider).valueOrNull ?? [];
  final filter = ref.watch(eventTypeFilterProvider);
  if (filter == null) return events;
  return events.where((e) => e.type == filter).toList();
});
