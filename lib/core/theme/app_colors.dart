import 'package:flutter/material.dart';

class AppColors {
  // ===== UNIFIED MODERN COLOR PALETTE =====
  // Primary: Vibrant Gold
  static const Color primary = Color(0xFFD4AF37);      // Premium Gold
  static const Color onPrimary = Color(0xFF000000);   // Black text on gold
  
  // Secondary: Emerald Green (accent)
  static const Color secondary = Color(0xFF00D084);   // Vibrant Green
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on green
  
  // Tertiary: Bright Blue
  static const Color tertiary = Color(0xFF2196F3);    // Professional Blue
  static const Color onTertiary = Color(0xFFFFFFFF);  // White text

  // ===== MODERN DARK SURFACES =====
  static const Color surfaceLowest = Color(0xFF0F0F0F);    // Pure dark background
  static const Color surfaceLow = Color(0xFF181818);       // Very dark gray
  static const Color surface = Color(0xFF1D1D1D);          // Main background
  static const Color surfaceHigh = Color(0xFF272727);      // Higher contrast
  static const Color surfaceHighest = Color(0xFF333333);   // Highest surface
  static const Color surfaceBright = Color(0xFF404040);    // Bright variant

  // ===== TEXT COLORS =====
  static const Color onSurface = Color(0xFFFFFFFF);        // Pure White text
  static const Color onSurfaceVariant = Color(0xFFD0D0D0); // Light Gray text

  // ===== OUTLINE / BORDERS =====
  static const Color outline = Color(0xFF4A4A4A);          // Mid-gray borders
  static const Color outlineVariant = Color(0xFF2F2F2F);   // Dark gray borders

  // ===== SPECIALTY COLORS =====
  static const Color coinGold = Color(0xFFFFD700);
  static const Color onCoinGold = Color(0xFF000000);

  // Status Colors - Enhanced
  static const Color error = Color(0xFFFF6B6B);       // Bright Red
  static const Color success = Color(0xFF00D084);     // Vibrant Green
  static const Color warning = Color(0xFFFF9800);     // Orange

  // ===== SCORE-BASED COLORS =====
  static const Color scoreExcellent = Color(0xFF00D084);  // Vibrant Green
  static const Color scoreGreat = Color(0xFF2196F3);      // Bright Blue
  static const Color scoreGood = Color(0xFFD4AF37);       // Gold
  static const Color scoreFair = Color(0xFFFF9800);       // Orange
  static const Color scoreLow = Color(0xFFFF6B6B);        // Red

  // ===== SCAN REPORT EXCLUSIVE COLORS =====
  static const Color scanReportBlack = Color(0xFF000000);      // Pure black
  static const Color scanReportGold = Color(0xFFD4AF37);        // Premium gold
  static const Color scanReportWhite = Color(0xFFFFFFFF);       // Pure white
  static const Color scanReportDarkGray = Color(0xFF1A1A1A);    // Almost black
  static const Color scanReportLightGray = Color(0xFFE8E8E8);   // Light gray


  // ===== GRADIENTS =====
  // Gold to Green gradient
  static const LinearGradient kineticGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFF1DBF73)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gold to Blue gradient
  static const LinearGradient kineticGradientAlt = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFF2196F3)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Premium gradient: Gold dominant
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFE5C158), Color(0xFFFFED4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== SHIMMER & SPECIAL EFFECTS =====
  static const Color shimmerColor = Color(0xFF2D3561);
  static const Color goldAccent = Color(0xFFfbbf24);
  static const Color darkAccent = Color(0xFF1f2937);
  static const Color lightAccent = Color(0xFFfef3c7);

  // Semantic Overlays & Scrims (for shadows, modals, etc)
  static const Color scrimDark = Color(0xFF000000); // Black scrim
  static const Color scrimLight = Color(0xFFffffff); // White scrim
  
  // Modal & Overlay Backgrounds
  static const Color modalOverlay = Color(0x80000000); // 50% black overlay
  static const Color lightOverlay = Color(0x1F1f2937); // 12% dark overlay
}
