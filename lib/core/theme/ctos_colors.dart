import 'package:flutter/material.dart';

class CtosColors {
  CtosColors._();

  // Base
  static const Color background  = Color(0xFF050A0E);
  static const Color surface     = Color(0xFF0D1B2A);
  static const Color surfaceAlt  = Color(0xFF0F2030);
  static const Color cardBorder  = Color(0xFF0A3040);
  static const Color gridLine    = Color(0xFF0A2533);

  // Accents
  static const Color cyan        = Color(0xFF00F5FF);
  static const Color cyanDim     = Color(0xFF00BFCC);
  static const Color cyanDark    = Color(0xFF007A8A);
  static const Color cyanGlow    = Color(0x3300F5FF);

  // Text
  static const Color textPrimary   = Color(0xFFE0F7FA);
  static const Color textSecondary = Color(0xFF80DEEA);
  static const Color textMuted     = Color(0xFF4A7080);

  // Status
  static const Color safe      = Color(0xFF00E676);
  static const Color safeDim   = Color(0xFF004D20);
  static const Color low       = Color(0xFF76FF03);
  static const Color moderate  = Color(0xFFFFD740);
  static const Color high      = Color(0xFFFF6D00);
  static const Color critical  = Color(0xFFFF1744);
  static const Color criticalDim = Color(0xFF4D0010);

  // Warning / alert
  static const Color amber     = Color(0xFFFFAB00);
  static const Color amberDim  = Color(0xFF4D3200);

  // VPN
  static const Color vpnActive   = Color(0xFF00E5FF);
  static const Color vpnInactive = Color(0xFF607D8B);

  static Color riskColor(int score) {
    if (score < 20) return safe;
    if (score < 40) return low;
    if (score < 60) return moderate;
    if (score < 80) return high;
    return critical;
  }

  static Color riskColorDim(int score) {
    if (score < 20) return safeDim;
    if (score < 40) return const Color(0xFF1A3000);
    if (score < 60) return const Color(0xFF3D2E00);
    if (score < 80) return const Color(0xFF3D1800);
    return criticalDim;
  }
}
