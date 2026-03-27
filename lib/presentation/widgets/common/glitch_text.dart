import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/ctos_colors.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration interval;
  final bool active;

  const GlitchText(
    this.text, {
    super.key,
    this.style,
    this.interval = const Duration(seconds: 3),
    this.active = true,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late Timer _timer;
  bool _glitching = false;
  double _offsetX = 0;
  double _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _scheduleGlitch();
  }

  void _scheduleGlitch() {
    _timer = Timer(widget.interval + Duration(milliseconds: _rng.nextInt(2000)),
        () async {
      if (!mounted || !widget.active) {
        _scheduleGlitch();
        return;
      }
      // Do 3-5 rapid glitch frames
      final frames = 3 + _rng.nextInt(3);
      for (int i = 0; i < frames; i++) {
        if (!mounted) break;
        setState(() {
          _glitching = true;
          _offsetX = (_rng.nextDouble() * 6 - 3);
          _offsetY = (_rng.nextDouble() * 2 - 1);
        });
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted) break;
        setState(() {
          _glitching = false;
          _offsetX = 0;
          _offsetY = 0;
        });
        await Future.delayed(const Duration(milliseconds: 40));
      }
      _scheduleGlitch();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.bodyLarge!;

    if (!_glitching) {
      return Text(widget.text, style: style);
    }

    return Stack(
      children: [
        // Cyan layer shifted left
        Transform.translate(
          offset: Offset(-_offsetX, -_offsetY),
          child: Text(
            widget.text,
            style: style.copyWith(color: CtosColors.cyan.withValues(alpha: 0.6)),
          ),
        ),
        // Red/magenta layer shifted right
        Transform.translate(
          offset: Offset(_offsetX, _offsetY),
          child: Text(
            widget.text,
            style: style.copyWith(
                color: const Color(0xFFFF0080).withValues(alpha: 0.6)),
          ),
        ),
        // Main text
        Text(widget.text, style: style),
      ],
    );
  }
}
