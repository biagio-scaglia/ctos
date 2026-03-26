import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ctos_colors.dart';

class CtosTheme {
  CtosTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CtosColors.background,
      primaryColor: CtosColors.cyan,
      colorScheme: const ColorScheme.dark(
        primary: CtosColors.cyan,
        secondary: CtosColors.cyanDim,
        surface: CtosColors.surface,
        error: CtosColors.critical,
        onPrimary: CtosColors.background,
        onSurface: CtosColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: CtosColors.cyan,
          letterSpacing: 4,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: CtosColors.textPrimary,
          letterSpacing: 3,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: CtosColors.textPrimary,
          letterSpacing: 2,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CtosColors.textPrimary,
          letterSpacing: 1.5,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 16,
          color: CtosColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 14,
          color: CtosColors.textSecondary,
          letterSpacing: 0.3,
        ),
        bodySmall: GoogleFonts.shareTechMono(
          fontSize: 11,
          color: CtosColors.textMuted,
          letterSpacing: 0.5,
        ),
        labelLarge: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CtosColors.cyan,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: CtosColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: CtosColors.cardBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CtosColors.cardBorder,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CtosColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: CtosColors.cyan,
          letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(color: CtosColors.cyan),
      ),
      iconTheme: const IconThemeData(color: CtosColors.cyan, size: 20),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CtosColors.surface,
        selectedItemColor: CtosColors.cyan,
        unselectedItemColor: CtosColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
