import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_info.dart';
import '../models/app_info.g.dart';
import '../models/network_connection.dart';
import '../models/network_connection.g.dart';
import '../models/device_event.dart';
import '../models/device_event.g.dart';
import '../models/app_behavior.dart';
import '../models/app_behavior.g.dart';
import '../../core/constants.dart';

class HiveService {
  static late Box<AppInfo> appBox;
  static late Box<NetworkConnection> networkBox;
  static late Box<DeviceEvent> eventBox;
  static late Box<AppBehaviorSnapshot> behaviorBox;

  static Future<void> init() async {
    // Register adapters
    Hive.registerAdapter(AppInfoAdapter());
    Hive.registerAdapter(NetworkConnectionAdapter());
    Hive.registerAdapter(DeviceEventTypeAdapter());
    Hive.registerAdapter(DeviceEventAdapter());
    Hive.registerAdapter(AppBehaviorSnapshotAdapter());

    // Open boxes
    appBox = await Hive.openBox<AppInfo>(CtosConstants.boxAppInfo);
    networkBox = await Hive.openBox<NetworkConnection>(CtosConstants.boxConnections);
    eventBox = await Hive.openBox<DeviceEvent>(CtosConstants.boxEvents);
    behaviorBox = await Hive.openBox<AppBehaviorSnapshot>(CtosConstants.boxBehavior);
  }

  // ── App Info ──────────────────────────────────────────────────────────────

  static Future<void> saveApp(AppInfo app) async {
    await appBox.put(app.packageName, app);
  }

  static Future<void> saveAllApps(List<AppInfo> apps) async {
    final map = {for (final a in apps) a.packageName: a};
    await appBox.putAll(map);
  }

  static List<AppInfo> getAllApps() => appBox.values.toList();

  // ── Network ───────────────────────────────────────────────────────────────

  static Future<void> saveConnections(List<NetworkConnection> conns) async {
    await networkBox.clear();
    for (int i = 0; i < conns.length; i++) {
      await networkBox.put(i, conns[i]);
    }
  }

  static List<NetworkConnection> getConnections() => networkBox.values.toList();

  // ── Events ────────────────────────────────────────────────────────────────

  static Future<void> addEvent(DeviceEvent event) async {
    await eventBox.put(event.id, event);
    await _pruneEvents();
  }

  static List<DeviceEvent> getEvents({int? limit, DeviceEventType? type}) {
    var events = eventBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (type != null) {
      events = events.where((e) => e.type == type).toList();
    }
    if (limit != null) {
      events = events.take(limit).toList();
    }
    return events;
  }

  static Future<void> _pruneEvents() async {
    if (eventBox.length > CtosConstants.maxEvents) {
      final sorted = eventBox.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = sorted.take(eventBox.length - CtosConstants.maxEvents);
      for (final e in toDelete) {
        await e.delete();
      }
    }
  }

  // ── Behavior ──────────────────────────────────────────────────────────────

  static Future<void> saveBehaviorSnapshot(AppBehaviorSnapshot snap) async {
    await behaviorBox.add(snap);
    await _pruneBehavior();
  }

  static List<AppBehaviorSnapshot> getBehaviorForApp(String packageName) {
    return behaviorBox.values
        .where((s) => s.packageName == packageName)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  static Future<void> _pruneBehavior() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toDelete = behaviorBox.values
        .where((s) => s.recordedAt.isBefore(cutoff))
        .toList();
    for (final s in toDelete) {
      await s.delete();
    }
  }
}
