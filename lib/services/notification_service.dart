import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _guardianChannel = MethodChannel('com.ctos.companion/guardian');

/// In-app notification queue + real Android push notifications via
/// CtosProtectionService (on Android only, silent on web/other platforms).
class NotificationService {
  static final _notifications = <CtosNotification>[];
  static final List<VoidCallback> _listeners = [];

  /// Called once at app startup. Starts the foreground protection service.
  static Future<void> init() async {
    if (!kIsWeb) {
      try {
        await _guardianChannel.invokeMethod('startProtection');
      } catch (_) {}
    }
  }

  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  static List<CtosNotification> get all => List.unmodifiable(_notifications);
  static int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Push a notification both in-app and as a real Android system notification.
  static void push({
    required String title,
    required String body,
    NotificationSeverity severity = NotificationSeverity.info,
  }) {
    // In-app queue
    _notifications.insert(
        0,
        CtosNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          severity: severity,
          timestamp: DateTime.now(),
        ));
    if (_notifications.length > 50) { _notifications.removeLast(); }
    for (final l in _listeners) { l(); }

    // Real Android notification (non-blocking)
    if (!kIsWeb) {
      final level = switch (severity) {
        NotificationSeverity.critical => 5,
        NotificationSeverity.warning  => 3,
        NotificationSeverity.info     => 1,
      };
      _guardianChannel.invokeMethod('showAlert', {
        'title': title,
        'body': body,
        'level': level,
      }).ignore();
    }
  }

  static void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      for (final l in _listeners) { l(); }
    }
  }

  static void markAllRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    for (final l in _listeners) { l(); }
  }
}

enum NotificationSeverity { info, warning, critical }

class CtosNotification {
  final String id;
  final String title;
  final String body;
  final NotificationSeverity severity;
  final DateTime timestamp;
  final bool read;

  const CtosNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.timestamp,
    this.read = false,
  });

  CtosNotification copyWith({bool? read}) => CtosNotification(
        id: id,
        title: title,
        body: body,
        severity: severity,
        timestamp: timestamp,
        read: read ?? this.read,
      );
}
