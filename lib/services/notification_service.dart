import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple in-app notification service (no external plugin dependency for demo).
/// In production, use flutter_local_notifications.
class NotificationService {
  static final _notifications = <CtosNotification>[];
  static final List<VoidCallback> _listeners = [];

  static Future<void> init() async {
    // In production: initialize flutter_local_notifications here
  }

  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) => _listeners.remove(listener);

  static List<CtosNotification> get all => List.unmodifiable(_notifications);
  static int get unreadCount => _notifications.where((n) => !n.read).length;

  static void push({
    required String title,
    required String body,
    NotificationSeverity severity = NotificationSeverity.info,
  }) {
    _notifications.insert(0, CtosNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      severity: severity,
      timestamp: DateTime.now(),
    ));

    // Keep max 50
    if (_notifications.length > 50) _notifications.removeLast();

    for (final l in _listeners) {
      l();
    }
  }

  static void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      for (final l in _listeners) l();
    }
  }

  static void markAllRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    for (final l in _listeners) l();
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
