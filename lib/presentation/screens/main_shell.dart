import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/scan_line_overlay.dart';
import '../widgets/hud/floating_hud.dart';
import '../widgets/common/ctos_bottom_nav.dart';
import '../../core/theme/ctos_colors.dart';
import '../../services/audio_service.dart';
import 'home/home_screen.dart';
import 'scan/scan_screen.dart';
import 'network/network_screen.dart';
import 'threat_center/threat_center_screen.dart';
import 'risk_dashboard/risk_dashboard_screen.dart';
import 'guardian/guardian_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    ScanScreen(),
    NetworkScreen(),
    ThreatCenterScreen(),
    RiskDashboardScreen(),
    GuardianScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: ScanLineOverlay(
        child: Stack(
          children: [
            IndexedStack(
              index: currentTab,
              children: _screens,
            ),
            const FloatingHud(),
          ],
        ),
      ),
      bottomNavigationBar: _CtosNav(
        currentIndex: currentTab,
        onTap: (i) {
          AudioService.playNavClick();
          ref.read(currentTabProvider.notifier).state = i;
        },
      ),
    );
  }
}

class _CtosNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CtosNav({required this.currentIndex, required this.onTap});

  static const _items = [
    ('HOME', Icons.home_outlined, Icons.home),
    ('SCAN', Icons.radar_outlined, Icons.radar),
    ('NET', Icons.hub_outlined, Icons.hub),
    ('THREATS', Icons.bug_report_outlined, Icons.bug_report),
    ('RISK', Icons.shield_outlined, Icons.shield),
    ('GUARD', Icons.security_outlined, Icons.security),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CtosColors.surface,
        border: const Border(
          top: BorderSide(color: CtosColors.cardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: CtosColors.cyan.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (label, icon, activeIcon) = _items[i];
              final selected = i == currentIndex;
              final isGuard = i == 5;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isGuard && selected
                          ? CtosColors.safe.withOpacity(0.08)
                          : Colors.transparent,
                      border: Border(
                        top: BorderSide(
                          color: selected
                              ? (isGuard ? CtosColors.safe : CtosColors.cyan)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? activeIcon : icon,
                          size: 20,
                          color: selected
                              ? (isGuard ? CtosColors.safe : CtosColors.cyan)
                              : CtosColors.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                            color: selected
                                ? (isGuard ? CtosColors.safe : CtosColors.cyan)
                                : CtosColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
