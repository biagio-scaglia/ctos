import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/device_provider.dart';
import '../../widgets/charts/radar_painter.dart';
import '../../widgets/common/glitch_text.dart';
import '../../widgets/common/hud_card.dart';
import '../../../core/utils/suspicion_calculator.dart';
import '../../../data/models/app_info.dart';
import '../../../services/audio_service.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final appsAsync = ref.watch(appsProvider);

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(title: const Text('SCAN')),
      body: Column(
        children: [
          // Radar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: appsAsync.when(
                data: (apps) => RadarWidget(
                  points: _buildRadarPoints(apps),
                  size: 240,
                ),
                loading: () => const RadarWidget(points: [], size: 240),
                error: (_, __) => const RadarWidget(points: [], size: 240),
              ),
            ),
          ),

          // Scan progress
          if (scanState.isScanning) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SCANNING ${scanState.appsScanned}/${scanState.totalApps}',
                        style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 11,
                          color: CtosColors.textMuted,
                        ),
                      ),
                      Text(
                        '${(scanState.progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          color: CtosColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: scanState.progress,
                    backgroundColor: CtosColors.gridLine,
                    valueColor: const AlwaysStoppedAnimation(CtosColors.cyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Scan button
          if (!scanState.isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  AudioService.playScanStart();
                  ref.read(scanProvider.notifier).startScan();
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: CtosColors.cyan),
                    color: CtosColors.cyan.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Text('INITIATE SCAN',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          color: CtosColors.cyan,
                          letterSpacing: 3,
                        )),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // App list
          Expanded(
            child: appsAsync.when(
              data: (apps) {
                final sorted = [...apps]
                  ..sort((a, b) => b.suspicionScore.compareTo(a.suspicionScore));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) =>
                      _AppTile(app: sorted[i], index: i),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: CtosColors.cyan),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: CtosColors.critical)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<RadarPoint> _buildRadarPoints(List<AppInfo> apps) {
    final rng = Random(42);
    return apps.map((app) {
      final angle = rng.nextDouble() * 2 * pi;
      final distance = 0.2 + (app.suspicionScore / 100) * 0.75;
      final color = CtosColors.riskColor(app.suspicionScore);
      return RadarPoint(angle: angle, distance: distance, color: color);
    }).toList();
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final int index;

  const _AppTile({required this.app, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = CtosColors.riskColor(app.suspicionScore);
    final label = SuspicionCalculator.label(app.suspicionScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HudCard(
        borderColor: color.withOpacity(0.3),
        padding: const EdgeInsets.all(12),
        onTap: () => _showDetail(context),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
                color: color.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  '${app.suspicionScore}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.displayName,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1),
                color: color.withOpacity(0.1),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    color: color,
                    letterSpacing: 1,
                  )),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideX(begin: 0.05),
    );
  }

  void _showDetail(BuildContext context) {
    final color = CtosColors.riskColor(app.suspicionScore);
    final reasons = SuspicionCalculator.reasons(app);

    showModalBottomSheet(
      context: context,
      backgroundColor: CtosColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        side: BorderSide(color: CtosColors.cyanDark),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            color: CtosColors.textPrimary,
                          )),
                      Text(app.packageName,
                          style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 10,
                            color: CtosColors.textMuted,
                          )),
                    ],
                  ),
                ),
                Text(
                  '${app.suspicionScore}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reasons.isNotEmpty) ...[
              const Text('WHY IS THIS APP FLAGGED?',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    color: CtosColors.textMuted,
                    letterSpacing: 2,
                  )),
              const SizedBox(height: 8),
              ...reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chevron_right,
                            size: 14, color: CtosColors.amber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 13,
                                color: CtosColors.textSecondary,
                              )),
                        ),
                      ],
                    ),
                  )),
            ] else
              const Text('No suspicious behavior detected.',
                  style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      color: CtosColors.safe)),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _DetailStat('CPU', '${app.cpuUsage.toStringAsFixed(1)}%'),
                _DetailStat('RAM', '${app.ramUsageMb.toStringAsFixed(0)}MB'),
                _DetailStat('NET', '${app.networkTrafficMb.toStringAsFixed(0)}MB'),
                _DetailStat('BATT', '${app.batteryImpact.toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                color: CtosColors.cyan,
                fontWeight: FontWeight.w700,
              )),
          Text(label,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 9,
                color: CtosColors.textMuted,
              )),
        ],
      ),
    );
  }
}
