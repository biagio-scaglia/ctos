import 'package:flutter/material.dart';
import '../../../core/theme/ctos_colors.dart';
import '../../../services/audio_service.dart';

class CtosBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CtosBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home, 'HOME'),
    _NavItem(Icons.radar_outlined, Icons.radar, 'SCAN'),
    _NavItem(Icons.hub_outlined, Icons.hub, 'NETWORK'),
    _NavItem(Icons.bug_report_outlined, Icons.bug_report, 'THREATS'),
    _NavItem(Icons.shield_outlined, Icons.shield, 'RISK'),
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
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioService.playNavClick();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: selected
                              ? CtosColors.cyan
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            key: ValueKey(selected),
                            size: 22,
                            color: selected
                                ? CtosColors.cyan
                                : CtosColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 9,
                            color: selected
                                ? CtosColors.cyan
                                : CtosColors.textMuted,
                            letterSpacing: 1.5,
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
