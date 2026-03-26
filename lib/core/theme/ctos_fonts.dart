import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ctos_colors.dart';

/// Centralized font helpers — use these instead of fontFamily strings.
/// GoogleFonts downloads fonts on first use and caches them.
class CtosFont {
  CtosFont._();

  static TextStyle orbitron({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = CtosColors.textPrimary,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle rajdhani({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = CtosColors.textPrimary,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double fontSize = 12,
    Color color = CtosColors.textMuted,
    double letterSpacing = 1,
  }) =>
      GoogleFonts.shareTechMono(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
      );
}
