import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/device_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../widgets/charts/risk_gauge.dart';
import '../../widgets/common/glitch_text.dart';
import '../../widgets/common/hud_card.dart';
import '../../widgets/common/animated_counter.dart';
import '../main_shell.dart';
import '../../../data/models/device_event.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risk = ref.watch(riskSnapshotProvider);
    final battery = ref.watch(batteryProvider).valueOrNull ?? 0;
    final cpu = ref.watch(cpuUsageProvider).valueOrNull ?? 0;
    final traffic = ref.watch(trafficProvider).valueOrNull ?? 0;
    final recentEvents = ref.watch(filteredTimelineProvider).take(3).toList();
    final vpn = ref.watch(vpnStatusProvider).valueOrNull;
    final suspiciousConns = ref.watch(suspiciousConnectionsCountProvider);

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(
        title: GlitchText(
          'CTOS COMPANION',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CtosColors.cyan,
            letterSpacing: 4,
          ),
        ),
        actions: [
          if (vpn?.isActive == true)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('VPN',
                    style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: CtosColors.vpnActive)),
                backgroundColor: CtosColors.vpnActive.withOpacity(0.1),
                side: const BorderSide(color: CtosColors.vpnActive),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Risk Gauge ────────────────────────────────────────────
          _buildRiskSection(context, ref, risk.totalScore, risk.level.name),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'BATTERY',
                  value: '$battery%',
                  icon: Icons.battery_charging_full_outlined,
                  color: battery < 20 ? CtosColors.critical : CtosColors.safe,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'CPU',
                  value: '${cpu.toStringAsFixed(1)}%',
                  icon: Icons.memory_outlined,
                  color: cpu > 70 ? CtosColors.high : CtosColors.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'NET',
                  value: traffic > 1000
                      ? '${(traffic / 1000).toStringAsFixed(1)}M'
                      : '${traffic.toInt()}K',
                  icon: Icons.wifi_outlined,
                  color: CtosColors.cyan,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          // ── Alert banner if critical ───────────────────────────────
          if (suspiciousConns > 0)
            HudCard(
              borderColor: CtosColors.amber,
              glowColor: CtosColors.amber.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: CtosColors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$suspiciousConns SUSPICIOUS NETWORK CONNECTION${suspiciousConns > 1 ? 'S' : ''} DETECTED',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 13,
                        color: CtosColors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          if (suspiciousConns > 0) const SizedBox(height: 12),

          // ── Scan CTA ──────────────────────────────────────────────
          _ScanButton(onTap: () {
            ref.read(currentTabProvider.notifier).state = 1;
          }),
          const SizedBox(height: 16),

          // ── Recent events ─────────────────────────────────────────
          if (recentEvents.isNotEmpty) ...[
            const _SectionHeader('RECENT ALERTS'),
            const SizedBox(height: 8),
            ...recentEvents.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _EventRow(event: e),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskSection(
      BuildContext context, WidgetRef ref, int score, String levelName) {
    return HudCard(
      borderColor: CtosColors.riskColor(score).withOpacity(0.5),
      glowColor: CtosColors.riskColor(score).withOpacity(0.2),
      child: Column(
        children: [
          const _SectionHeader('DEVICE RISK LEVEL'),
          const SizedBox(height: 16),
          Center(child: RiskGauge(score: score, size: 200)),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HudCard(
      borderColor: color.withOpacity(0.3),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          Text(label,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 9,
                color: CtosColors.textMuted,
                letterSpacing: 1.5,
              )),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: CtosColors.cyan, width: 1),
          color: CtosColors.cyan.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
                color: CtosColors.cyan.withOpacity(0.2), blurRadius: 12)
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar, color: CtosColors.cyan, size: 20),
            SizedBox(width: 12),
            Text(
              'START FULL SCAN',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CtosColors.cyan,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3.seconds, color: CtosColors.cyan.withOpacity(0.2));
  }
}

class _EventRow extends StatelessWidget {
  final dynamic event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event as DeviceEvent;
    final color = _severityColor(e.severityLevel);

    return HudCard(
      borderColor: color.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(_eventIcon(e.type), color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.typeLabel,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    )),
                if (e.relatedApp != null)
                  Text(e.relatedApp!,
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: CtosColors.textMuted,
                      )),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(e.timestamp),
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: CtosColors.textMuted,
            ),
          ),
        ],
      ),
    );
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
        DeviceEventType.vpnDetected => Icons.vpn_key_outlined,
        DeviceEventType.vpnDisconnected => Icons.vpn_key_off_outlined,
        DeviceEventType.accessibilityEnabled => Icons.accessibility_outlined,
        DeviceEventType.unusualNetworkConnection => Icons.hub_outlined,
        _ => Icons.warning_amber_outlined,
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: CtosColors.cyan),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CtosColors.textMuted,
              letterSpacing: 3,
            )),
      ],
    );
  }
}
