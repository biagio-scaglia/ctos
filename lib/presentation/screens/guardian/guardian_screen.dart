import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../../services/security_guardian_service.dart';
import '../../../services/url_safety_service.dart';
import '../../widgets/common/glitch_text.dart';
import '../../widgets/common/hud_card.dart';
import '../../widgets/common/scan_line_overlay.dart';

// Provider for live guardian advice feed
final guardianAdviceProvider =
    StreamProvider<GuardianAdvice>((ref) => SecurityGuardianService.adviceStream);

class GuardianScreen extends ConsumerStatefulWidget {
  const GuardianScreen({super.key});

  @override
  ConsumerState<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends ConsumerState<GuardianScreen> {
  final _urlController = TextEditingController();
  UrlSafetyResult? _lastResult;
  bool _checking = false;
  final List<GuardianAdvice> _adviceLog = [];

  static const _guardianChannel = MethodChannel('com.ctos.companion/guardian');

  @override
  void initState() {
    super.initState();
    SecurityGuardianService.adviceStream.listen((advice) {
      if (mounted) setState(() => _adviceLog.insert(0, advice));
    });
    // Listen for URLs shared from Chrome / other browsers
    _guardianChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedUrl' && mounted) {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          _urlController.text = url;
          _checkUrl();
        }
      }
    });
    // Also check if a URL was shared before this screen was open
    _checkPendingSharedUrl();
  }

  Future<void> _checkPendingSharedUrl() async {
    try {
      final url =
          await _guardianChannel.invokeMethod<String?>('getSharedUrl');
      if (url != null && url.isNotEmpty && mounted) {
        _urlController.text = url;
        _checkUrl();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = SecurityGuardianService.isActive;

    return Scaffold(
      backgroundColor: CtosColors.background,
      appBar: AppBar(
        title: GlitchText(
          'SECURITY GUARDIAN',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            color: CtosColors.cyan,
            letterSpacing: 3,
          ),
        ),
      ),
      body: ScanLineOverlay(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Guardian Status Card ────────────────────────────────
            _GuardianStatusCard(isActive: isActive),
            const SizedBox(height: 16),

            // ── URL Safety Checker ──────────────────────────────────
            HudCard(
              borderColor: CtosColors.cyanDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: CtosColors.cyan, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'URL SAFETY CHECKER',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 11,
                          color: CtosColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 13,
                            color: CtosColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'https://example.com',
                            hintStyle: const TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 12,
                              color: CtosColors.textMuted,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: CtosColors.cardBorder),
                              borderRadius: BorderRadius.zero,
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: CtosColors.cyan),
                              borderRadius: BorderRadius.zero,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.paste,
                                  size: 16, color: CtosColors.textMuted),
                              onPressed: () async {
                                final data =
                                    await Clipboard.getData(Clipboard.kTextPlain);
                                if (data?.text != null) {
                                  _urlController.text = data!.text!;
                                }
                              },
                            ),
                          ),
                          onSubmitted: (_) => _checkUrl(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _checking ? null : _checkUrl,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: CtosColors.cyan.withOpacity(0.15),
                            border: Border.all(color: CtosColors.cyan),
                          ),
                          child: _checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: CtosColors.cyan,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : const Text(
                                  'SCAN',
                                  style: TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 11,
                                    color: CtosColors.cyan,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_lastResult != null) ...[
                    const SizedBox(height: 12),
                    _UrlResultCard(result: _lastResult!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Security Tips ────────────────────────────────────────
            HudCard(
              borderColor: CtosColors.cyanDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          color: CtosColors.cyan, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'SECURITY TIPS',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 11,
                          color: CtosColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._securityTips.map((tip) => _TipRow(tip: tip)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Guardian Log ─────────────────────────────────────────
            if (_adviceLog.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.history, color: CtosColors.textMuted, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'GUARDIAN LOG',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: CtosColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._adviceLog.take(5).map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _AdviceCard(advice: a),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _checking = true;
      _lastResult = null;
    });

    // Small delay for UX feel
    await Future.delayed(const Duration(milliseconds: 600));
    final result = UrlSafetyService.analyze(url);

    setState(() {
      _lastResult = result;
      _checking = false;
    });
  }
}

class _GuardianStatusCard extends StatelessWidget {
  final bool isActive;
  const _GuardianStatusCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return HudCard(
      borderColor: isActive
          ? CtosColors.safe.withOpacity(0.5)
          : CtosColors.textMuted.withOpacity(0.3),
      glowColor: isActive ? CtosColors.safe.withOpacity(0.2) : Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isActive)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CtosColors.safe.withOpacity(0.1),
                  ),
                ),
              Icon(
                Icons.shield_outlined,
                color: isActive ? CtosColors.safe : CtosColors.textMuted,
                size: 32,
              ),
            ],
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 1500.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1, 1),
                duration: 1500.ms,
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlitchText(
                  isActive ? 'GUARDIAN ACTIVE' : 'GUARDIAN INACTIVE',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? CtosColors.safe : CtosColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Monitoring your device in real time. You are protected.'
                      : 'Run a scan to activate the guardian.',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    color: CtosColors.textSecondary,
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
              color: isActive ? CtosColors.safe : CtosColors.textMuted,
              boxShadow: isActive
                  ? [BoxShadow(color: CtosColors.safe, blurRadius: 8)]
                  : null,
            ),
          ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
        ],
      ),
    );
  }
}

class _UrlResultCard extends StatelessWidget {
  final UrlSafetyResult result;
  const _UrlResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = switch (result.risk) {
      UrlRisk.safe => CtosColors.safe,
      UrlRisk.suspicious => CtosColors.moderate,
      UrlRisk.phishing => CtosColors.critical,
      UrlRisk.malicious => CtosColors.critical,
      UrlRisk.unknown => CtosColors.textMuted,
    };

    final icon = switch (result.risk) {
      UrlRisk.safe => Icons.check_circle_outline,
      UrlRisk.suspicious => Icons.warning_amber_outlined,
      UrlRisk.phishing => Icons.phishing_outlined,
      UrlRisk.malicious => Icons.dangerous_outlined,
      UrlRisk.unknown => Icons.help_outline,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.verdict,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  color: color.withOpacity(0.1),
                ),
                child: Text(
                  '${result.score}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (result.flags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.flags.map((f) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withOpacity(0.5)),
                      color: color.withOpacity(0.08),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 9,
                        color: color,
                      ),
                    ),
                  )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

class _AdviceCard extends StatelessWidget {
  final GuardianAdvice advice;
  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    final color = switch (advice.severity) {
      5 => CtosColors.critical,
      4 => CtosColors.high,
      3 => CtosColors.moderate,
      _ => CtosColors.cyan,
    };

    return HudCard(
      borderColor: color.withOpacity(0.3),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice.title,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    )),
                Text(advice.message,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      color: CtosColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final _SecurityTip tip;
  const _TipRow({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tip.icon, color: tip.color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tip.color,
                    )),
                Text(tip.body,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      color: CtosColors.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTip {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _SecurityTip({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

const _securityTips = [
  _SecurityTip(
    icon: Icons.vpn_key_outlined,
    title: 'Always use HTTPS',
    body: 'Check for 🔒 in your browser before entering passwords or payment info.',
    color: CtosColors.cyan,
  ),
  _SecurityTip(
    icon: Icons.wifi_outlined,
    title: 'Avoid public Wi-Fi without VPN',
    body: 'Public networks can intercept unencrypted traffic. Use a VPN.',
    color: CtosColors.amber,
  ),
  _SecurityTip(
    icon: Icons.apps_outlined,
    title: 'Review app permissions regularly',
    body: 'Revoke camera/microphone access for apps that don\'t need it.',
    color: CtosColors.amber,
  ),
  _SecurityTip(
    icon: Icons.link,
    title: 'Check URLs before clicking',
    body: 'Use this checker before visiting unfamiliar links in emails or SMS.',
    color: CtosColors.cyan,
  ),
  _SecurityTip(
    icon: Icons.update_outlined,
    title: 'Keep your OS updated',
    body: 'Security patches fix known vulnerabilities exploited by malware.',
    color: CtosColors.safe,
  ),
  _SecurityTip(
    icon: Icons.lock_outlined,
    title: 'Use unique passwords',
    body: 'A password manager helps generate and store strong, unique passwords.',
    color: CtosColors.safe,
  ),
];
