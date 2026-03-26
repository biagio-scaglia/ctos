import 'package:flutter/material.dart';
import '../../../core/theme/ctos_colors.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final int maxValue;
  final TextStyle? style;
  final Duration duration;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.maxValue = 100,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, val, _) {
        final display = val.round();
        final color = CtosColors.riskColor(
            maxValue == 100 ? display : (display * 100 ~/ maxValue));

        return Text(
          '$display$suffix',
          style: (style ??
                  const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ))
              .copyWith(color: color),
        );
      },
    );
  }
}

/// Scrolling random digits — matrix style, settles on the real value
class MatrixCounter extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration settleAfter;

  const MatrixCounter({
    super.key,
    required this.value,
    this.style,
    this.settleAfter = const Duration(milliseconds: 1200),
  });

  @override
  State<MatrixCounter> createState() => _MatrixCounterState();
}

class _MatrixCounterState extends State<MatrixCounter> {
  late String _displayed;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _displayed = _randomString(widget.value.length);
    _animate();
  }

  void _animate() async {
    final steps = 12;
    final stepDelay = widget.settleAfter.inMilliseconds ~/ steps;

    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: stepDelay));
      if (!mounted) return;
      // Progressively reveal correct characters from left
      final revealed = (i / steps * widget.value.length).ceil();
      final random = _randomString(widget.value.length - revealed);
      setState(() {
        _displayed = widget.value.substring(0, revealed) + random;
      });
    }

    if (!mounted) return;
    setState(() {
      _displayed = widget.value;
      _settled = true;
    });
  }

  String _randomString(int len) {
    const chars = '0123456789ABCDEF';
    return List.generate(
        len, (_) => chars[(DateTime.now().microsecond + _) % chars.length]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style ??
          TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 14,
            color: _settled ? CtosColors.cyan : CtosColors.cyanDim,
            letterSpacing: 2,
          ),
    );
  }
}
