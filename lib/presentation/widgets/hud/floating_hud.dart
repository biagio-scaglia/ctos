import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../providers/device_provider.dart';
import '../../providers/network_provider.dart';

/// Floating HUD overlay showing battery + network speed
class FloatingHud extends ConsumerStatefulWidget {
  const FloatingHud({super.key});

  @override
  ConsumerState<FloatingHud> createState() => _FloatingHudState();
}

class _FloatingHudState extends ConsumerState<FloatingHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  Offset _position = const Offset(16, 100);
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final battery = ref.watch(batteryProvider).valueOrNull ?? 0;
    final traffic = ref.watch(trafficProvider).valueOrNull ?? 0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onPanUpdate: (d) =>
              setState(() => _position += d.delta),
          child: Container(
            width: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CtosColors.surface.withValues(alpha: 0.9),
              border: Border.all(color: CtosColors.cyanDark, width: 1),
              boxShadow: [
                BoxShadow(
                  color: CtosColors.cyan.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('CTOS',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: CtosColors.cyan,
                          letterSpacing: 2,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _visible = false),
                      child: const Icon(Icons.close,
                          size: 12, color: CtosColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _HudRow(
                  icon: _batteryIcon(battery),
                  label: 'BAT',
                  value: '$battery%',
                  color: battery < 20 ? CtosColors.critical : CtosColors.safe,
                ),
                const SizedBox(height: 4),
                _HudRow(
                  icon: Icons.speed_outlined,
                  label: 'NET',
                  value: traffic > 1000
                      ? '${(traffic / 1000).toStringAsFixed(1)}M'
                      : '${traffic.toInt()}K',
                  color: CtosColors.cyan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _batteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_5_bar;
    if (level > 40) return Icons.battery_3_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}

class _HudRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 9,
              color: CtosColors.textMuted,
            )),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}
