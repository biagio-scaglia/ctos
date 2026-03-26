import 'dart:async';
import '../data/models/device_event.dart';
import '../data/models/app_info.dart';
import '../data/models/network_connection.dart';
import 'event_service.dart';
import 'notification_service.dart';
import 'audio_service.dart';

/// The Security Guardian monitors in real time and proactively alerts the user.
/// It acts as the "always-on" protection layer.
class SecurityGuardianService {
  static Timer? _timer;
  static bool _active = false;

  static bool get isActive => _active;

  static final _adviceController = StreamController<GuardianAdvice>.broadcast();
  static Stream<GuardianAdvice> get adviceStream => _adviceController.stream;

  /// Start monitoring — call once after first scan
  static void start({
    required List<AppInfo> Function() getApps,
    required List<NetworkConnection> Function() getConnections,
  }) {
    if (_active) return;
    _active = true;

    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _runChecks(getApps(), getConnections());
    });
  }

  static Future<void> _runChecks(
    List<AppInfo> apps,
    List<NetworkConnection> connections,
  ) async {
    // ── Check 1: Critical suspicion score ─────────────────────────
    for (final app in apps) {
      if (app.suspicionScore >= 80) {
        final advice = GuardianAdvice(
          type: GuardianAdviceType.criticalApp,
          title: 'HIGH RISK APP DETECTED',
          message: '${app.displayName} has a critical suspicion score of ${app.suspicionScore}. '
              'Consider uninstalling or revoking its permissions.',
          severity: 5,
          relatedApp: app.displayName,
          actionLabel: 'VIEW IN THREATS',
        );
        _emit(advice);
        break; // one at a time
      }
    }

    // ── Check 2: Accessibility services (spyware vector) ──────────
    final accessibilityApps = apps.where((a) => a.hasAccessibilityService).toList();
    if (accessibilityApps.length > 1) {
      _emit(GuardianAdvice(
        type: GuardianAdviceType.accessibilityWarning,
        title: 'MULTIPLE ACCESSIBILITY SERVICES',
        message: '${accessibilityApps.length} apps have Accessibility access enabled. '
            'This can allow them to read your screen and intercept inputs.',
        severity: 4,
        actionLabel: 'VIEW PERMISSIONS',
      ));
    }

    // ── Check 3: Unusual connections ──────────────────────────────
    final suspicious = connections.where((c) => c.suspicionScore > 70).toList();
    if (suspicious.isNotEmpty) {
      final c = suspicious.first;
      _emit(GuardianAdvice(
        type: GuardianAdviceType.suspiciousConnection,
        title: 'SUSPICIOUS CONNECTION',
        message: 'Active connection to ${c.remoteIp}:${c.port} '
            '${c.flags.isNotEmpty ? "(${c.flags.join(', ')})" : ""} '
            'with suspicion score ${c.suspicionScore}.',
        severity: 3,
        actionLabel: 'VIEW NETWORK',
      ));
    }

    // ── Check 4: Apps auto-starting on boot ───────────────────────
    final bootApps = apps.where((a) => a.startsOnBoot && a.suspicionScore > 30).toList();
    if (bootApps.isNotEmpty) {
      _emit(GuardianAdvice(
        type: GuardianAdviceType.autoStartWarning,
        title: 'AUTO-START APPS DETECTED',
        message: '${bootApps.map((a) => a.displayName).take(3).join(', ')} '
            'start automatically on boot and have elevated risk scores.',
        severity: 3,
        actionLabel: 'VIEW THREATS',
      ));
    }
  }

  static void _emit(GuardianAdvice advice) {
    _adviceController.add(advice);

    NotificationService.push(
      title: advice.title,
      body: advice.message,
      severity: advice.severity >= 4
          ? NotificationSeverity.critical
          : advice.severity == 3
              ? NotificationSeverity.warning
              : NotificationSeverity.info,
    );

    if (advice.severity >= 4) {
      AudioService.playAlert();
    } else if (advice.severity >= 3) {
      AudioService.playBeep();
    }

    EventService.addEvent(DeviceEvent(
      id: 'guardian_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: DeviceEventType.suspiciousProcess,
      description: advice.message,
      severityLevel: advice.severity,
    ));
  }

  static void stop() {
    _timer?.cancel();
    _active = false;
  }

  static void dispose() {
    stop();
    _adviceController.close();
  }
}

enum GuardianAdviceType {
  criticalApp,
  suspiciousConnection,
  accessibilityWarning,
  autoStartWarning,
  vpnRecommendation,
  urlWarning,
  behaviorChange,
}

class GuardianAdvice {
  final GuardianAdviceType type;
  final String title;
  final String message;
  final int severity; // 1-5
  final String? relatedApp;
  final String? actionLabel;
  final DateTime timestamp;

  GuardianAdvice({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.relatedApp,
    this.actionLabel,
  }) : timestamp = DateTime.now();
}
