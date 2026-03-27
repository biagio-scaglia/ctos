import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/ctos_colors.dart';

class RadarWidget extends StatefulWidget {
  final List<RadarPoint> points;
  final double size;

  const RadarWidget({
    super.key,
    required this.points,
    this.size = 280,
  });

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _RadarPainter(
            sweepAngle: _ctrl.value * 2 * pi,
            points: widget.points,
          ),
        ),
      ),
    );
  }
}

class RadarPoint {
  final double angle;   // radians
  final double distance; // 0.0 - 1.0 (% of radius)
  final Color color;
  final String label;

  const RadarPoint({
    required this.angle,
    required this.distance,
    this.color = CtosColors.cyan,
    this.label = '',
  });
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<RadarPoint> points;

  const _RadarPainter({required this.sweepAngle, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // — Background rings ——————————————————————————————————————————————
    final ringPaint = Paint()
      ..color = CtosColors.gridLine
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, ringPaint);
    }

    // — Cross lines ———————————————————————————————————————————————————
    final crossPaint = Paint()
      ..color = CtosColors.gridLine
      ..strokeWidth = 0.5;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center,
        center + Offset(cos(angle) * radius, sin(angle) * radius),
        crossPaint,
      );
    }

    // — Sweep gradient ————————————————————————————————————————————————
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + pi / 2,
        colors: [
          CtosColors.cyan.withValues(alpha: 0),
          CtosColors.cyan.withValues(alpha: 0.25),
          CtosColors.cyan.withValues(alpha: 0),
        ],
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // — Sweep line ————————————————————————————————————————————————————
    final linePaint = Paint()
      ..color = CtosColors.cyan.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      center,
      center + Offset(cos(sweepAngle) * radius, sin(sweepAngle) * radius),
      linePaint,
    );

    // — Outer ring ————————————————————————————————————————————————————
    final outerPaint = Paint()
      ..color = CtosColors.cyan.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, outerPaint);

    // — Points ————————————————————————————————————————————————————————
    for (final point in points) {
      final r = radius * point.distance;
      final x = center.dx + cos(point.angle) * r;
      final y = center.dy + sin(point.angle) * r;

      // Glow
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = point.color.withValues(alpha: 0.3),
      );
      // Dot
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = point.color,
      );

      // Flash if sweep is near
      final angleDiff = (sweepAngle - point.angle).abs() % (2 * pi);
      if (angleDiff < 0.3 || angleDiff > 2 * pi - 0.3) {
        canvas.drawCircle(
          Offset(x, y),
          8,
          Paint()..color = point.color.withValues(alpha: 0.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.sweepAngle != sweepAngle;
}
