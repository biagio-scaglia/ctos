import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/risk_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/charts/risk_gauge.dart';
import '../../widgets/charts/traffic_graph.dart';
import '../../widgets/common/hud_card.dart';
import '../../widgets/common/glitch_text.dart';
import '../../../core/utils/risk_level_engine.dart';

class RiskDashboardScreen extends ConsumerWidget {
  const RiskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(riskSnapshotProvider);
    final history = ref.watch(riskHistoryProvider);
    final apps = ref.watch(appsProvider).valueOrNull ?? [];
    final conns = ref.watch(connectionsProvider).valueOrNull ?? [];

    final topThreats = [...apps]
      ..sort((a, b) => b.suspicionScore.compareTo(a.suspicionScore));
    final topThreatsTop3 = topThreats.take(3).toList();

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(
        title: GlitchText(
          'RISK DASHBOARD',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 15,
            color: CtosColors.cyan,
            letterSpacing: 3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Main gauge ─────────────────────────────────────────────
          HudCard(
            borderColor: CtosColors.riskColor(snap.totalScore).withOpacity(0.4),
            glowColor: CtosColors.riskColor(snap.totalScore).withOpacity(0.2),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: RiskGauge(score: snap.totalScore, size: 220),
                ),
                const SizedBox(height: 8),
                Text(
                  RiskLevelEngine.levelLabel(snap.level),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    letterSpacing: 4,
                    color: CtosColors.riskColor(snap.totalScore),
                  ),
                ),
                const SizedBox(height: 16),
                // Score breakdown
                Row(
                  children: [
                    _BreakdownItem(
                      label: 'APPS',
                      value: snap.appRisk,
                      maxValue: 50,
                      icon: Icons.apps_outlined,
                    ),
                    _BreakdownItem(
                      label: 'NETWORK',
                      value: snap.networkRisk,
                      maxValue: 30,
                      icon: Icons.hub_outlined,
                    ),
                    _BreakdownItem(
                      label: 'EVENTS',
                      value: snap.eventRisk,
                      maxValue: 20,
                      icon: Icons.timeline_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 16),

          // ── Risk history sparkline ─────────────────────────────────
          if (history.length > 1)
            HudCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('RISK HISTORY (24H)'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: TrafficSparkline(
                      data: history
                          .map((s) => s.totalScore.toDouble())
                          .toList(),
                      color: CtosColors.riskColor(snap.totalScore),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          // ── Top threats ────────────────────────────────────────────
          const _SectionLabel('TOP THREATS'),
          const SizedBox(height: 8),
          ...topThreatsTop3.asMap().entries.map((e) {
            final app = e.value;
            final color = CtosColors.riskColor(app.suspicionScore);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HudCard(
                borderColor: color.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        color: color.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        app.displayName,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CtosColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${app.suspicionScore}',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: e.key * 100)).fadeIn();
          }),

          const SizedBox(height: 16),

          // ── Recommendations ────────────────────────────────────────
          const _SectionLabel('RECOMMENDATIONS'),
          const SizedBox(height: 8),
          ..._buildRecommendations(snap, apps, conns).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HudCard(
                  borderColor: r.color.withOpacity(0.3),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(r.icon, color: r.color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title,
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: r.color,
                                )),
                            Text(r.body,
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 12,
                                  color: CtosColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<_Recommendation> _buildRecommendations(
    RiskSnapshot snap,
    List<dynamic> apps,
    List<dynamic> conns,
  ) {
    final recs = <_Recommendation>[];

    if (snap.totalScore > 60) {
      recs.add(_Recommendation(
        icon: Icons.shield_outlined,
        title: 'Review suspicious apps',
        body: 'You have apps with high suspicion scores. Visit Threat Center for details.',
        color: CtosColors.critical,
      ));
    }

    if (snap.networkRisk > 15) {
      recs.add(_Recommendation(
        icon: Icons.vpn_key_outlined,
        title: 'Consider using a VPN',
        body: 'Unusual network connections detected. A VPN can encrypt your traffic.',
        color: CtosColors.amber,
      ));
    }

    if (snap.appRisk > 30) {
      recs.add(_Recommendation(
        icon: Icons.delete_outline,
        title: 'Remove unused apps',
        body: 'Apps with high permission usage increase your attack surface.',
        color: CtosColors.amber,
      ));
    }

    if (snap.totalScore < 30) {
      recs.add(_Recommendation(
        icon: Icons.check_circle_outline,
        title: 'Your device looks clean',
        body: 'No significant threats detected. Keep running periodic scans.',
        color: CtosColors.safe,
      ));
    }

    return recs;
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final IconData icon;

  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxValue == 0 ? 0.0 : value / maxValue;
    final color = CtosColors.riskColor((pct * 100).round());

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 9,
              color: CtosColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: CtosColors.gridLine,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Recommendation {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  _Recommendation({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: CtosColors.cyan),
        const SizedBox(width: 8),
        Text(text,
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
