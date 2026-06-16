import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette
  static const Color bg = Color(0xFF050D0A); // Deep black/dark green
  static const Color bgSecondary = Color(0xFF0A1A12); // Dark green
  static const Color surface = Color(0xFF0A1F15); // Dark glass panels base
  static const Color surface2 = Color(0xFF0D261A);
  static const Color surface3 = Color(0xFF103322);
  static const Color border = Color(0xFF16402A);
  static const Color borderLight = Color(0xFF1C5938);
  
  static const Color primary = Color(0xFF00FF87); // Neon/emerald green
  static const Color primaryDark = Color(0xFF10B981);
  static const Color primaryGlow = Color(0x4000FF87);
  
  static const Color secondary = Color(0xFFF5C842); // Rich gold
  static const Color secondaryGlow = Color(0x33F5C842);
  
  static const Color success = Color(0xFF22C55E);
  static const Color successDim = Color(0x1F22C55E);
  
  static const Color warning = Color(0xFFD4A017); // Rich gold variant
  static const Color warningDim = Color(0x1FD4A017);
  
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDim = Color(0x1FEF4444);
  
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFFA3B8AC); // Greenish grey
  static const Color textMuted = Color(0xFF5A7264); // Darker greenish grey

  static const Color glassBg = Color(0x0AFFFFFF); // Dark glass panels
  static const Color glassBorder = Color(0x14FFFFFF);

  // Backward compatibility
  static const Color background = bg;

  // Gradients
  static const Gradient gradientHero = LinearGradient(
    colors: [Color(0xFF050D0A), Color(0xFF0A1A12)], // Deep black/dark green gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient gradientAccent = LinearGradient(
    colors: [primary, secondary], // Green to Gold
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF00FF87), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Backward compatibility for existing gradients
  static const Gradient primaryGradient = gradientAccent;

  static const Gradient backgroundGradient = LinearGradient(
    colors: [bg, bgSecondary, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: glassBorder,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
