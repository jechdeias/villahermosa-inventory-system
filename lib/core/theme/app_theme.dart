import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the app's design tokens (colors, spacing,
/// radii, text styles) and the global [ThemeData].
///
/// Fonts come from `google_fonts`, with the Inter and JetBrains Mono files
/// bundled under `assets/google_fonts/` so text renders identically offline
/// (this app is offline-first — it must not depend on a runtime download).
class AppTheme {
  const AppTheme._();

  // ── Colors ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1E1E1E);
  static const Color primaryLight = Color(0xFF2A2A2A);
  static const Color background = Color(0xFFF4F4F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Sidebar (admin + warehouse)
  static const Color sidebarBg = Color(0xFF1E1E1E);
  static const Color sidebarActive = Color(0xFF2A2A2A);
  static const Color sidebarText = Color(0xFF9CA3AF);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // ── Spacing ─────────────────────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacing2XL = 24.0;
  static const double spacing3XL = 32.0;

  // ── Border radius ───────────────────────────────────────────────────────────
  static const double radiusSM = 6.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusFull = 100.0;

  // ── Text styles (Inter) ─────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary);
  static TextStyle get headingLarge => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get headingMedium => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get headingSmall => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get bodyLarge => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary);
  static TextStyle get bodySmall => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted);
  static TextStyle get caption => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: textLight);
  static TextStyle get labelMedium => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted);

  /// Font family name for const TextStyles (registered in pubspec.yaml).
  static const String monoFamily = 'JetBrainsMono';

  /// Order numbers, SKUs and other codes.
  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary);

  // ── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: const ColorScheme.light(
          primary: primary,
          surface: surface,
          error: error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMD), borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMD), borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMD), borderSide: const BorderSide(color: primary, width: 1.5)),
          hintStyle: GoogleFonts.inter(fontSize: 13, color: textLight),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLG), side: const BorderSide(color: border)),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary,
          labelStyle: GoogleFonts.inter(fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull), side: const BorderSide(color: border)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textLight,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        ),
      );
}
