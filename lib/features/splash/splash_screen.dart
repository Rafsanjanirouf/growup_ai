import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'auth_gate.dart';

/// Pure UI splash screen.
/// Responsibilities: play the intro video, run the fade animation,
/// then navigate to [AuthGate] which handles all auth + routing logic.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ── Fade animation — starts immediately so content is always visible ───
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Start fade right away
    _fadeController.forward();

    // ── Navigate to AuthGate after splash duration ─────────────────────────
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Background: image ───────────────────
          SizedBox.expand(
            child: Image.asset(
              'assets/image/avater_image.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── 2. Dark overlay ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.bg.withAlpha(50),
                  AppTheme.bg.withAlpha(140),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── 3. Animated content ─────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.blur_on_rounded,
                          color: AppTheme.secondary,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AURA',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          ' AI',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3.0,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),

                    // Center glassmorphic card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: AppTheme.glassBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.glassBorder,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(26),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.secondary.withAlpha(77),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Text(
                                  'Aesthetics & Lookmaxxing',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Tagline
                              Text(
                                'Chisel Your Face\nElevate Your Aura',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  color: AppTheme.textPrimary,
                                  shadows: [
                                    Shadow(
                                      color: AppTheme.bg.withAlpha(128),
                                      offset: const Offset(0, 2),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Description
                              Text(
                                'Scan your facial features in real time, analyze skin layout boundaries, follow dynamic Mewing sessions, and build a chiseled jawline today.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom: loading dots + footer
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 56,
                          child: _LoadingDots(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Powered by Ai (1.0 Vision)',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated loading dots ────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_anim.value - delay).clamp(0.0, 1.0);
            final opacity =
                (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
