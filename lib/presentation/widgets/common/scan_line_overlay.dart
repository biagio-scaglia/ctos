import 'package:flutter/material.dart';

class ScanLineOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  final int lineSpacing;

  const ScanLineOverlay({
    super.key,
    required this.child,
    this.opacity = 0.04,
    this.lineSpacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ScanLinePainter(
                  opacity: opacity,
                  lineSpacing: lineSpacing,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double opacity;
  final int lineSpacing;

  const _ScanLinePainter({required this.opacity, required this.lineSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.opacity != opacity || old.lineSpacing != lineSpacing;
}

/// Animated scanline that sweeps top to bottom
class AnimatedScanLine extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedScanLine({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => CustomPaint(
                painter: _SweepLinePainter(progress: _anim.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SweepLinePainter extends CustomPainter {
  final double progress;
  const _SweepLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x0000F5FF),
          const Color(0x2200F5FF),
          const Color(0x0000F5FF),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 20, size.width, 40),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SweepLinePainter old) =>
      old.progress != progress;
}
