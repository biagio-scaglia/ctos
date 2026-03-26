import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/timeline_provider.dart';
import '../../widgets/common/hud_card.dart';
import '../../../data/models/device_event.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(filteredTimelineProvider);
    final filter = ref.watch(eventTypeFilterProvider);

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(
        title: const Text('TIMELINE'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: filter != null ? CtosColors.cyan : CtosColors.textMuted,
            ),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: events.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: CtosColors.textMuted, size: 48),
                  SizedBox(height: 12),
                  Text('No events recorded yet.',
                      style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 16,
                          color: CtosColors.textMuted)),
                  Text('Run a scan to start monitoring.',
                      style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 11,
                          color: CtosColors.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, i) {
                final event = events[i];
                final showDate = i == 0 ||
                    !_sameDay(events[i - 1].timestamp, event.timestamp);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDate) _DateDivider(event.timestamp),
                    _TimelineEventCard(event: event, index: i),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CtosColors.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FILTER BY TYPE',
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 11,
                  color: CtosColors.textMuted,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'ALL',
                  selected: ref.read(eventTypeFilterProvider) == null,
                  onTap: () {
                    ref.read(eventTypeFilterProvider.notifier).state = null;
                    Navigator.pop(ctx);
                  },
                ),
                ...DeviceEventType.values.map((t) => _FilterChip(
                      label: t.name.toUpperCase(),
                      selected: ref.read(eventTypeFilterProvider) == t,
                      onTap: () {
                        ref.read(eventTypeFilterProvider.notifier).state = t;
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: CtosColors.cyanDark),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(date).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: CtosColors.textMuted,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final DeviceEvent event;
  final int index;

  const _TimelineEventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(event.severityLevel);

    return HudCard(
      borderColor: color.withOpacity(0.3),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(event.timestamp),
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 11,
                    color: CtosColors.cyan,
                  ),
                ),
                Text(
                  DateFormat('ss').format(event.timestamp),
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 9,
                    color: CtosColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: color.withOpacity(0.4),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_eventIcon(event.type), size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      event.typeLabel,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    _SeverityBadge(event.severityLevel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    color: CtosColors.textSecondary,
                  ),
                ),
                if (event.relatedApp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'App: ${event.relatedApp}',
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: CtosColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: (index * 40).clamp(0, 400))).fadeIn();
  }

  Color _severityColor(int sev) => switch (sev) {
        5 => CtosColors.critical,
        4 => CtosColors.high,
        3 => CtosColors.moderate,
        2 => CtosColors.low,
        _ => CtosColors.cyan,
      };

  IconData _eventIcon(DeviceEventType type) => switch (type) {
        DeviceEventType.cameraAccess => Icons.camera_alt_outlined,
        DeviceEventType.microphoneAccess => Icons.mic_outlined,
        DeviceEventType.locationAccess => Icons.location_on_outlined,
        DeviceEventType.networkSpike => Icons.trending_up,
        DeviceEventType.wakeLock => Icons.lock_clock_outlined,
        DeviceEventType.appAutoStart => Icons.play_arrow_outlined,
        DeviceEventType.permissionGranted => Icons.check_circle_outline,
        DeviceEventType.permissionRevoked => Icons.remove_circle_outline,
        DeviceEventType.suspiciousProcess => Icons.bug_report_outlined,
        DeviceEventType.batteryDrain => Icons.battery_alert_outlined,
        DeviceEventType.vpnDetected => Icons.vpn_key_outlined,
        DeviceEventType.vpnDisconnected => Icons.vpn_key_off_outlined,
        DeviceEventType.accessibilityEnabled => Icons.accessibility_outlined,
        DeviceEventType.unusualNetworkConnection => Icons.hub_outlined,
        DeviceEventType.highCpuUsage => Icons.speed_outlined,
      };
}

class _SeverityBadge extends StatelessWidget {
  final int level;
  const _SeverityBadge(this.level);

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      5 => CtosColors.critical,
      4 => CtosColors.high,
      3 => CtosColors.moderate,
      2 => CtosColors.low,
      _ => CtosColors.cyan,
    };
    final label = switch (level) {
      5 => 'CRIT',
      4 => 'HIGH',
      3 => 'MED',
      2 => 'LOW',
      _ => 'INFO',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.8),
        color: color.withOpacity(0.1),
      ),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 8,
            color: color,
            letterSpacing: 1,
          )),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? CtosColors.cyan : CtosColors.cardBorder,
          ),
          color: selected ? CtosColors.cyan.withOpacity(0.15) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 10,
            color: selected ? CtosColors.cyan : CtosColors.textMuted,
          ),
        ),
      ),
    );
  }
}
