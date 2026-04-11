import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // ==================== PROFESSIONAL FONT FAMILIES ====================
  // Using Google Fonts for dynamic font loading

  // ==================== HEADING STYLES (Roboto Bold) ====================
  static TextStyle get displayLarge => GoogleFonts.roboto(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: AppColors.onSurface,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.roboto(
    fontSize: 44,
    fontWeight: FontWeight.w900,
    color: AppColors.onSurface,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.roboto(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get headlineLarge => GoogleFonts.roboto(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.roboto(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.roboto(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: 0,
    height: 1.35,
  );

  // ==================== TITLE STYLES (Open Sans SemiBold) ====================
  static TextStyle get titleLarge => GoogleFonts.openSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.openSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.15,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.openSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.2,
    height: 1.4,
  );

  // ==================== BODY STYLES (Open Sans Regular) ====================
  static TextStyle get bodyLarge => GoogleFonts.openSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    letterSpacing: 0.3,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.openSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.openSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.2,
    height: 1.5,
  );

  // ==================== LABEL STYLES (Open Sans SemiBold) ====================
  static TextStyle get labelLarge => GoogleFonts.openSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.35,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.openSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.openSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // ==================== SPECIAL STYLES ====================
  /// Premium CTA Button Text
  static TextStyle get ctaButton => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.onPrimary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  /// Large CTA Button
  static TextStyle get ctaButtonLarge => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.onPrimary,
    letterSpacing: 0.6,
    height: 1.3,
  );

  /// Secondary CTA
  static TextStyle get secondaryButton => GoogleFonts.openSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.4,
    height: 1.3,
  );

  /// Overline (Uppercase captions)
  static TextStyle get caption => GoogleFonts.openSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.2,
    height: 1.3,
  );

  /// Eyebrow text (small accent)
  static TextStyle get eyebrow => GoogleFonts.openSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.primary,
    height: 1.3,
  );

  // ==================== TEXT THEME FOR MATERIAL ====================
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
