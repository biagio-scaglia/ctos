import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/network_provider.dart';
import '../../widgets/charts/traffic_graph.dart';
import '../../widgets/common/hud_card.dart';
import '../../widgets/common/glitch_text.dart';
import '../../../data/models/network_connection.dart';
import '../../../data/models/vpn_status.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final trafficHistory = ref.watch(trafficHistoryProvider);
    final vpnAsync = ref.watch(vpnStatusProvider);
    final traffic = ref.watch(trafficProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(
        title: const Text('NETWORK'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.speed_outlined, size: 14, color: CtosColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  traffic > 1000
                      ? '${(traffic / 1000).toStringAsFixed(1)} Mbps'
                      : '${traffic.toInt()} Kbps',
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 11,
                    color: CtosColors.cyan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── VPN Status ─────────────────────────────────────────────
          vpnAsync.when(
            data: (vpn) => _VpnCard(vpn: vpn),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // ── Traffic chart ──────────────────────────────────────────
          HudCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('LIVE TRAFFIC'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: TrafficChart(data: trafficHistory),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Connections ────────────────────────────────────────────
          const _SectionLabel('ACTIVE CONNECTIONS'),
          const SizedBox(height: 8),
          connectionsAsync.when(
            data: (conns) {
              final sorted = [...conns]
                ..sort((a, b) => b.suspicionScore.compareTo(a.suspicionScore));
              return Column(
                children: sorted
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ConnectionTile(
                            conn: e.value,
                            index: e.key,
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: CtosColors.cyan),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: CtosColors.critical),
            ),
          ),
        ],
      ),
    );
  }
}

class _VpnCard extends StatelessWidget {
  final VpnStatus vpn;
  const _VpnCard({required this.vpn});

  @override
  Widget build(BuildContext context) {
    final active = vpn.isActive;
    final color = active ? CtosColors.vpnActive : CtosColors.vpnInactive;

    return HudCard(
      borderColor: color.withOpacity(0.5),
      glowColor: active ? color.withOpacity(0.3) : Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            active ? Icons.vpn_key_outlined : Icons.vpn_key_off_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'VPN ACTIVE' : 'NO VPN DETECTED',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (active && vpn.interfaceName != null)
                  Text(
                    'Interface: ${vpn.interfaceName}  ${vpn.serverIp ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: CtosColors.textMuted,
                    ),
                  ),
                if (!active)
                  const Text(
                    'Traffic is NOT encrypted by a VPN',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: CtosColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: active
                  ? [BoxShadow(color: color, blurRadius: 6)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final NetworkConnection conn;
  final int index;

  const _ConnectionTile({required this.conn, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = CtosColors.riskColor(conn.suspicionScore);
    final isHighRisk = conn.suspicionScore > 50;

    return HudCard(
      borderColor: isHighRisk ? color.withOpacity(0.4) : CtosColors.cardBorder,
      glowColor:
          isHighRisk ? color.withOpacity(0.15) : Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      '${conn.remoteIp}:${conn.port}  ${conn.protocol}',
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: CtosColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${conn.suspicionScore}',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '${conn.trafficKbps.toStringAsFixed(0)} kbps',
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                      color: CtosColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (conn.flags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: conn.flags
                  .map((f) => _Flag(f, color: isHighRisk ? color : CtosColors.textMuted))
                  .toList(),
            ),
          ],
          if (conn.country != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: CtosColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${conn.country}${conn.provider != null ? ' · ${conn.provider}' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    color: CtosColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.05);
  }
}

class _Flag extends StatelessWidget {
  final String label;
  final Color color;

  const _Flag(this.label, {this.color = CtosColors.textMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        color: color.withOpacity(0.08),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'ShareTechMono',
          fontSize: 9,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'ShareTechMono',
        fontSize: 10,
        color: CtosColors.textMuted,
        letterSpacing: 3,
      ),
    );
  }
}
