import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/device_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/common/hud_card.dart';
import '../../widgets/common/glitch_text.dart';
import '../../../core/utils/suspicion_calculator.dart';
import '../../../data/models/app_info.dart';
import '../../../data/models/network_connection.dart';
import '../../../services/app_behavior_service.dart';

class ThreatCenterScreen extends ConsumerWidget {
  const ThreatCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(appsProvider);
    final connectionsAsync = ref.watch(connectionsProvider);

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(
        title: const GlitchText(
          'THREAT CENTER',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 15,
            color: CtosColors.critical,
            letterSpacing: 3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Suspicious apps ────────────────────────────────────────
          _buildSectionHeader('SUSPICIOUS APPS'),
          const SizedBox(height: 8),
          appsAsync.when(
            data: (apps) {
              final suspicious = apps
                  .where((a) => a.suspicionScore >= 20)
                  .toList()
                ..sort((a, b) => b.suspicionScore.compareTo(a.suspicionScore));

              if (suspicious.isEmpty) {
                return HudCard(
                  borderColor: CtosColors.safe.withValues(alpha: 0.3),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: CtosColors.safe, size: 20),
                      SizedBox(width: 12),
                      Text('No suspicious apps detected.',
                          style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 14,
                              color: CtosColors.safe)),
                    ],
                  ),
                );
              }

              return Column(
                children: suspicious
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ThreatAppCard(app: e.value, index: e.key),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: CtosColors.cyan),
            ),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: CtosColors.critical)),
          ),
          const SizedBox(height: 16),

          // ── Suspicious connections ─────────────────────────────────
          _buildSectionHeader('SUSPICIOUS CONNECTIONS'),
          const SizedBox(height: 8),
          connectionsAsync.when(
            data: (conns) {
              final suspicious = conns
                  .where((c) => c.suspicionScore > 50)
                  .toList()
                ..sort((a, b) => b.suspicionScore.compareTo(a.suspicionScore));

              if (suspicious.isEmpty) {
                return HudCard(
                  borderColor: CtosColors.safe.withValues(alpha: 0.3),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: CtosColors.safe, size: 20),
                      SizedBox(width: 12),
                      Text('No suspicious connections.',
                          style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 14,
                              color: CtosColors.safe)),
                    ],
                  ),
                );
              }

              return Column(
                children: suspicious
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ThreatConnCard(conn: e.value, index: e.key),
                        ))
                    .toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // ── Worsening apps (behavior trend) ───────────────────────
          appsAsync.maybeWhen(
            data: (apps) {
              final worsening = AppBehaviorService.getWorsening(apps);
              if (worsening.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('BEHAVIOR TREND: WORSENING'),
                  const SizedBox(height: 8),
                  ...worsening.map((pkg) {
                    final app = apps.firstWhere((a) => a.packageName == pkg,
                        orElse: () => apps.first);
                    final summary = AppBehaviorService.getSummary(pkg);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HudCard(
                        borderColor: CtosColors.amber.withValues(alpha: 0.4),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: CtosColors.amber, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(app.displayName,
                                      style: const TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: CtosColors.textPrimary,
                                      )),
                                  Text(
                                    'Score increased +${summary.suspicionTrend.toStringAsFixed(0)} pts in 24h',
                                    style: const TextStyle(
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 10,
                                      color: CtosColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 14,
            color: title.contains('SUSPICIOUS') || title.contains('THREAT')
                ? CtosColors.critical
                : CtosColors.amber),
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

class _ThreatAppCard extends StatelessWidget {
  final AppInfo app;
  final int index;

  const _ThreatAppCard({required this.app, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = CtosColors.riskColor(app.suspicionScore);
    final reasons = SuspicionCalculator.reasons(app);

    return HudCard(
      borderColor: color.withValues(alpha: 0.4),
      glowColor: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.displayName,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CtosColors.textPrimary,
                        )),
                    Text(app.packageName,
                        style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 9,
                          color: CtosColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                  color: color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text('${app.suspicionScore}',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Score bar
          ClipRRect(
            child: LinearProgressIndicator(
              value: app.suspicionScore / 100,
              backgroundColor: CtosColors.gridLine,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 10),
          // Top reasons
          ...reasons.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 14, color: color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(r,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 12,
                            color: CtosColors.textSecondary,
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideX(begin: 0.05);
  }
}

class _ThreatConnCard extends StatelessWidget {
  final NetworkConnection conn;
  final int index;

  const _ThreatConnCard({required this.conn, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = CtosColors.riskColor(conn.suspicionScore);

    return HudCard(
      borderColor: color.withValues(alpha: 0.4),
      glowColor: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: CtosColors.critical, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conn.hostname.isNotEmpty ? conn.hostname : conn.remoteIp,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CtosColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${conn.remoteIp}:${conn.port} · ${conn.flags.join(' · ')}',
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 9,
                    color: CtosColors.textMuted,
                  ),
                ),
                if (conn.country != null)
                  Text(
                    '${conn.country} · ${conn.provider ?? 'Unknown provider'}',
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      color: CtosColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${conn.suspicionScore}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn();
  }
}
