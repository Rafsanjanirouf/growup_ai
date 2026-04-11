import 'package:flutter/material.dart';

class AppColors {
  // ===== UNIFIED 4-COLOR PALETTE =====
  // Primary: Gold/Yellow
  static const Color primary = Color(0xFFD4AF37);      // Premium Gold
  static const Color onPrimary = Color(0xFF000000);   // Black text on gold
  
  // Secondary: Emerald Green (accent)
  static const Color secondary = Color(0xFF1DBF73);   // Vibrant Green
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on green
  
  // Tertiary: Sky Blue (more conservative)
  static const Color tertiary = Color(0xFF2196F3);    // Professional Blue
  static const Color onTertiary = Color(0xFFFFFFFF);  // White text

  // ===== SURFACE TONAL LAYERING (Dark Mode - Optimized for Gold Primary) =====
  // Ultra-dark surfaces to make gold pop
  static const Color surfaceLowest = Color(0xFF0D0D0D);    // Pure Black-ish background
  static const Color surfaceLow = Color(0xFF1A1A1A);       // Very dark gray - Card backgrounds
  static const Color surface = Color(0xFF1F1F1F);          // Dark gray - Main background
  static const Color surfaceHigh = Color(0xFF2A2A2A);      // Higher contrast layer
  static const Color surfaceHighest = Color(0xFF3A3A3A);   // Highest surface layer
  static const Color surfaceBright = Color(0xFF4A4A4A);    // Bright surface variant

  // ===== TEXT COLORS =====
  static const Color onSurface = Color(0xFFFFFFFF);        // Pure White text
  static const Color onSurfaceVariant = Color(0xFFCCCCCC); // Light Gray text - secondary

  // ===== OUTLINE / BORDERS =====
  static const Color outline = Color(0xFF555555);          // Mid-gray borders
  static const Color outlineVariant = Color(0xFF333333);   // Dark gray borders

  // ===== SPECIALTY COLORS =====
  // Coin/Rewards (keeping gold for coins)
  static const Color coinGold = Color(0xFFFFD700);
  static const Color onCoinGold = Color(0xFF000000);

  // Status Colors
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);

  // ===== SCAN REPORT EXCLUSIVE COLORS (Black, Gold, White) =====
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
