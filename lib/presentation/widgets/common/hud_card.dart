import 'package:flutter/material.dart';
import '../../../core/theme/ctos_colors.dart';

class HudCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color? glowColor;
  final EdgeInsetsGeometry padding;
  final double cornerSize;
  final VoidCallback? onTap;

  const HudCard({
    super.key,
    required this.child,
    this.borderColor = CtosColors.cyanDark,
    this.glowColor,
    this.padding = const EdgeInsets.all(16),
    this.cornerSize = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? borderColor.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CtosColors.surface,
          boxShadow: [
            BoxShadow(
              color: glow,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _HudBorderPainter(
            borderColor: borderColor,
            cornerSize: cornerSize,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _HudBorderPainter extends CustomPainter {
  final Color borderColor;
  final double cornerSize;

  const _HudBorderPainter({
    required this.borderColor,
    required this.cornerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cs = cornerSize;
    final path = Path()
      // Top-left corner
      ..moveTo(0, cs)
      ..lineTo(0, 0)
      ..lineTo(cs, 0)
      // Top-right corner
      ..moveTo(size.width - cs, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cs)
      // Bottom-right corner
      ..moveTo(size.width, size.height - cs)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - cs, size.height)
      // Bottom-left corner
      ..moveTo(cs, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - cs);

    canvas.drawPath(path, paint);

    // Subtle inner border
    final innerPaint = Paint()
      ..color = borderColor.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HudBorderPainter old) =>
      old.borderColor != borderColor || old.cornerSize != cornerSize;
}

/// Small label chip in CTOS style
class HudChip extends StatelessWidget {
  final String label;
  final Color color;

  const HudChip(this.label, {super.key, this.color = CtosColors.cyan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        color: color.withOpacity(0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'ShareTechMono',
          fontSize: 10,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
