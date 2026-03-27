import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../widgets/common/glitch_text.dart';
import '../../widgets/common/scan_line_overlay.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _bootLines = [
    'INITIALIZING CTOS v2.0...',
    'LOADING THREAT DATABASE...',
    'SCANNING DEVICE ENVIRONMENT...',
    'CALIBRATING SUSPICION ENGINE...',
    'ESTABLISHING SECURE CHANNEL...',
    'SYSTEM READY.',
  ];

  final List<String> _displayed = [];
  int _currentLine = 0;

  @override
  void initState() {
    super.initState();
    _startBoot();
  }

  void _startBoot() {
    Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (_currentLine >= _bootLines.length) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/main');
          }
        });
        return;
      }
      if (mounted) {
        setState(() {
          _displayed.add(_bootLines[_currentLine++]);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CtosColors.background,
      body: ScanLineOverlay(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                // Logo
                Column(
                  children: [
                    const Icon(Icons.shield_outlined,
                            size: 72, color: CtosColors.cyan)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.5, 0.5)),
                    const SizedBox(height: 16),
                    GlitchText(
                      'CTOS',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: CtosColors.cyan,
                        letterSpacing: 12,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'COMPANION SECURITY SYSTEM',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 14,
                        color: CtosColors.textMuted,
                        letterSpacing: 4,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
                const Spacer(),
                // Boot log
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: CtosColors.cardBorder),
                    color: CtosColors.surface.withValues(alpha: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BOOT LOG',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 10,
                          color: CtosColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._displayed.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '> ',
                                  style: TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 11,
                                    color: CtosColors.cyan.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  e.value,
                                  style: TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 11,
                                    color: e.key == _displayed.length - 1
                                        ? CtosColors.cyan
                                        : CtosColors.textMuted,
                                  ),
                                ).animate().fadeIn(duration: 200.ms),
                              ],
                            ),
                          )),
                      // Cursor blink
                      if (_currentLine < _bootLines.length)
                        const Text(
                          '█',
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 11,
                            color: CtosColors.cyan,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).fadeIn(
                            duration: 400.ms).then().fadeOut(duration: 400.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: _displayed.length / _bootLines.length,
                  backgroundColor: CtosColors.gridLine,
                  valueColor: const AlwaysStoppedAnimation(CtosColors.cyan),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
