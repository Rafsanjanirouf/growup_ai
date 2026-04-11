import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get kineticNebulaTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface, // No pure black for main background
      primaryColor: AppColors.primary,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),

      textTheme: AppTypography.textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Glassmorphism typically handled in custom widgets
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Typically overridden by Kinetic Gradient
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0, // No default material shadows, handled physically
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(48), // 'xl' radius or 3rem
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh, // Standard card background
        elevation: 0, // No material shadow
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 'md/lg' radius
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
        size: 24,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.surfaceLowest,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.transparent, // Enforcing No-Line Rule
        space: 24,
        thickness: 0,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5), // Ghost Border focus
        ),
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
      ),
    );
  }
}
