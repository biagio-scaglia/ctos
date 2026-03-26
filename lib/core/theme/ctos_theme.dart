import 'package:flutter/material.dart';
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
      fontFamily: 'Rajdhani',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: CtosColors.cyan,
          letterSpacing: 4,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: CtosColors.textPrimary,
          letterSpacing: 3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: CtosColors.textPrimary,
          letterSpacing: 2,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CtosColors.textPrimary,
          letterSpacing: 1.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 16,
          color: CtosColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14,
          color: CtosColors.textSecondary,
          letterSpacing: 0.3,
        ),
        bodySmall: TextStyle(
          fontFamily: 'ShareTechMono',
          fontSize: 11,
          color: CtosColors.textMuted,
          letterSpacing: 0.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CtosColors.cyan,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardTheme(
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
      appBarTheme: const AppBarTheme(
        backgroundColor: CtosColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: CtosColors.cyan,
          letterSpacing: 3,
        ),
        iconTheme: IconThemeData(color: CtosColors.cyan),
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
