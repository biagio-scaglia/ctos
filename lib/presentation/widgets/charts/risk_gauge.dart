import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/ctos_colors.dart';

class RiskGauge extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;

  const RiskGauge({
    super.key,
    required this.score,
    this.size = 200,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = CtosColors.riskColor(score);
    final label = _riskLabel(score);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, _) => CustomPaint(
              size: Size(size, size),
              painter: _GaugePainter(progress: value, color: color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, val, _) => Text(
                  val.round().toString(),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (showLabel)
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: size * 0.08,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 3,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _riskLabel(int score) => switch (score) {
        < 20 => 'SECURE',
        < 40 => 'LOW RISK',
        < 60 => 'MODERATE',
        < 80 => 'HIGH RISK',
        _ => 'CRITICAL',
      };
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = 0.75 * pi;   // bottom-left
    const sweepMax = 1.5 * pi;      // 270 degrees

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax,
      false,
      Paint()
        ..color = CtosColors.gridLine
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Colored progress arc
    if (progress > 0) {
      // Build gradient from green to red
      final shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepMax,
        colors: const [
          CtosColors.safe,
          CtosColors.low,
          CtosColors.moderate,
          CtosColors.high,
          CtosColors.critical,
        ],
        stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepMax * progress,
        false,
        Paint()
          ..shader = shader
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks
    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepMax * i / 10);
      final isMain = i % 5 == 0;
      final tickLen = isMain ? 12.0 : 6.0;
      final outerR = radius + 6;
      final innerR = outerR - tickLen;

      canvas.drawLine(
        center + Offset(cos(angle) * innerR, sin(angle) * innerR),
        center + Offset(cos(angle) * outerR, sin(angle) * outerR),
        Paint()
          ..color = CtosColors.textMuted.withValues(alpha: 0.5)
          ..strokeWidth = isMain ? 1.5 : 0.8,
      );
    }

    // Needle indicator at progress position
    final needleAngle = startAngle + sweepMax * progress;
    final needleEnd = center +
        Offset(cos(needleAngle) * (radius - 2), sin(needleAngle) * (radius - 2));
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}
