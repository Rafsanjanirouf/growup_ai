import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

// Core Themes and Providers
import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/scan_history_provider.dart';
import 'core/services/subscription_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/local_db_service.dart';
import 'core/providers/daily_progress_provider.dart';
import 'core/services/backup_preference_service.dart';
import 'core/services/notification_service.dart';

// Onboarding Feature Screens
import 'features/onboarding/auth_screen.dart';
import 'features/onboarding/signup_screen.dart';
import 'features/onboarding/profile_setup_screen.dart';
import 'features/onboarding/goal_selection_screen.dart';
import 'features/onboarding/backup_consent_screen.dart';

// Scan Feature Screens
import 'features/scan/camera_scan_screen.dart';
import 'features/scan/scanning_process_screen.dart';
import 'features/scan/paywall_screen.dart';
import 'features/scan/scan_detail_screen.dart';

// Dashboard, Analytics & Profile Screens
import 'features/dashboard/dashboard_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/backup_settings_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  // Initialise backup gate before anything else
  await BackupPreferenceService().init(prefs);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notifications
  await NotificationService().init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GrowUpAIApp(),
    ),
  );
}

class GrowUpAIApp extends StatelessWidget {
  const GrowUpAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Lookmaxxing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Entry point Splash video screen
      initialRoute: '/',
      routes: {
        '/': (context) => const VideoSplashHome(),
        '/auth': (context) => const AuthScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/goals': (context) => const GoalSelectionScreen(),
        '/backup-consent': (context) => const BackupConsentScreen(),
        '/camera-scan': (context) => const CameraScanScreen(),
        '/scanning-process': (context) => const ScanningProcessScreen(),
        '/paywall': (context) => const PaywallScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/backup-settings': (context) => const BackupSettingsScreen(),
      },
    );
  }
}

class VideoSplashHome extends ConsumerStatefulWidget {
  const VideoSplashHome({super.key});

  @override
  ConsumerState<VideoSplashHome> createState() => _VideoSplashHomeState();
}

class _VideoSplashHomeState extends ConsumerState<VideoSplashHome>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showAuthButton = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _controller = VideoPlayerController.asset('assets/videos/splash_bg.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          _controller.setVolume(0.0);
          _controller.play();
          _fadeController.forward();
        }
      }).catchError((error) {
        debugPrint("Error loading splash video: $error");
        if (mounted) _fadeController.forward();
      });

    // Always run auth check and navigate — never leave user on splash
    _checkAuthAndRoute();
  }

  // ─── Main Auth Check & Routing Logic ──────────────────────────────────────
  Future<void> _checkAuthAndRoute() async {
    // Brief splash visibility so the beautiful video and animation plays
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // ── NOT LOGGED IN → Stop checking, let user click the button ──────────
    if (user == null) {
      if (mounted) setState(() => _showAuthButton = true);
      return;
    }

    // ── LOGGED IN → init services ──────────────────────────────────────────
    try {
      await SubscriptionService().init(userId: user.uid);
    } catch (e) {
      debugPrint('SubscriptionService init error: $e');
    }

    // Background: push unsynced scans (fire and forget)
    SyncService().syncPendingScans();

    // ── Fetch user doc from Firestore ──────────────────────────────────────
    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'growupai',
      );
      final doc = await db.collection('users').doc(user.uid).get();

      if (!mounted) return;

      // User doc doesn't exist yet → onboarding
      if (!doc.exists) {
        Navigator.of(context).pushReplacementNamed('/profile-setup');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // ── TEMPORARY: Inject Gift Subscription for specific UID ──────────────
      if (user.uid == 'KdZcxQdzfIZrcmRXXxPQmHIDfXb2') {
        try {
          final subDocRef = db.collection('subscription').doc(user.uid);
          final subDoc = await subDocRef.get();
          if (!subDoc.exists || subDoc.data()?['subscription_category'] != 'Gift') {
            debugPrint('Injecting Gift Subscription for ${user.uid}...');
            await subDocRef.set({
              'custom_subscription': true,
              'subscription_category': 'Gift',
              'custom_sub_start_date': Timestamp.now(),
              'custom_sub_end_date': Timestamp.fromDate(
                  DateTime.now().add(const Duration(days: 365))),
            }, SetOptions(merge: true));
          }
        } catch (e) {
          debugPrint('Error injecting subscription override: $e');
        }
      }
      // ─────────────────────────────────────────────────────────────────────

      // ── Onboarding not completed → profile setup ──────────────────────────
      final bool onboardingCompleted = data['onboarding_completed'] ?? false;
      if (!onboardingCompleted) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/profile-setup');
        return;
      }

      // ── Sync user profile from Firestore to local ────────────────────────
      final String fsName = data['display_name'] ?? '';
      final int fsAge = data['age'] ?? 18;
      final String fsGender = data['gender'] ?? 'Male';
      final double fsAuraScore = (data['aura_score'] as num?)?.toDouble() ?? 0.0;
      final String fsCoachLanguage = data['coach_language'] ?? 'English';
      final String? morningTime = data['aura_morning_time'];
      final String? noonTime = data['aura_noon_time'];
      final String? eveningTime = data['aura_evening_time'];
      final String? nightTime = data['aura_night_time'];
      
      final userNotifier = ref.read(userStateProvider.notifier);
      await userNotifier.updateProfile(name: fsName, age: fsAge, gender: fsGender);
      await userNotifier.updateAuraScore(fsAuraScore);
      await userNotifier.updateLanguage(fsCoachLanguage);
      await userNotifier.updateNotificationTimes(
        morningTime: morningTime,
        noonTime: noonTime,
        eveningTime: eveningTime,
        nightTime: nightTime,
      );
      // ── Streak: check last_open_date and update accordingly ────────────────
      await userNotifier.checkAndUpdateStreak(user.uid);

      // ── Sync Daily Progress ────────────────────────────────────────────────
      try {
        final rawProgress = await SyncService().fetchRemoteDailyProgress();
        if (rawProgress.isNotEmpty) {
          final mapped = rawProgress.map((d) => DailyProgress(
            dateKey: d['date_key'] ?? '',
            date: DateTime.parse(d['date_key']), // Approximation since dateKey is YYYY-MM-DD
            completed: d['completed_count'] ?? 0,
            total: d['total_count'] ?? 9,
          )).toList();
          await ref.read(dailyProgressProvider.notifier).syncFromFirestore(mapped);
        }
      } catch (e) {
        debugPrint('Failed to sync daily progress: $e');
      }

      // ── Backup consent not shown → consent screen ─────────────────────────
      if (!BackupPreferenceService().hasShownConsent) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/backup-consent');
        return;
      }

      // ── Determine Pro status (RevenueCat first, then custom override) ──────
      bool isPro = false;
      try {
        isPro = await SubscriptionService().isProEntitled();
      } catch (e) {
        debugPrint('RevenueCat check error: $e');
      }

      if (!isPro) {
        // Check custom subscription override from Firestore
        try {
          final subDoc = await db.collection('subscription').doc(user.uid).get();
          if (subDoc.exists) {
            final subData = subDoc.data() as Map<String, dynamic>;
            final bool hasCustomSub = subData['custom_subscription'] ?? false;
            final String category = subData['subscription_category'] ?? '';
            if (hasCustomSub || category == 'Gift') {
              final dynamic endDateRaw = subData['custom_sub_end_date'];
              if (endDateRaw is Timestamp) {
                if (endDateRaw.toDate().isAfter(DateTime.now())) {
                  isPro = true;
                  debugPrint('Custom subscription valid → isPro = true');
                } else {
                  debugPrint('Custom subscription expired on ${endDateRaw.toDate()}');
                  try { await subDoc.reference.update({'custom_subscription': false}); } catch (_) {}
                }
              } else {
                debugPrint('Custom subscription: no valid end date → assumed lifetime/gift');
                isPro = true;
              }
            }
          }
        } catch (e) {
          debugPrint('Custom subscription check error: $e');
        }
      }

      // Sync isPro state locally
      final localIsPro = ref.read(userStateProvider).isPro;
      if (localIsPro != isPro) {
        await ref.read(userStateProvider.notifier).setPro(isPro);
        debugPrint('isPro synced: $localIsPro → $isPro');
        try {
          await db.collection('users').doc(user.uid).update({'is_pro': isPro});
        } catch (e) {
          debugPrint('Firestore isPro sync failed: $e');
        }
      }

      if (!mounted) return;

      // ── NOT PRO → Paywall ─────────────────────────────────────────────────
      if (!isPro) {
        Navigator.of(context).pushReplacementNamed('/paywall');
        return;
      }

      // ── PRO: handle paywall_pending flag ─────────────────────────────────
      final prefs = ref.read(sharedPreferencesProvider);
      final paywallPending = prefs.getBool('paywall_pending') ?? false;
      if (paywallPending) {
        await prefs.setBool('paywall_pending', false);
        final scanList = ref.read(scanHistoryProvider);
        if (mounted) {
          if (scanList.isNotEmpty) {
            final latestScan = scanList.first;
            final previousScan = scanList.length > 1 ? scanList[1] : null;
            Navigator.of(context).pushReplacementNamed('/dashboard');
            await Future.delayed(const Duration(milliseconds: 150));
            if (mounted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    ScanDetailScreen(scan: latestScan, previousScan: previousScan),
              ));
            }
          } else {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        }
        return;
      }

      // ── PRO: Regular navigation based on scan history ─────────────────────
      // First try local SQLite correctly by awaiting the DB read
      final localScans = await LocalDbService().getAllScans(user.uid);

      if (localScans.isEmpty) {
        // No local scans — try recovering from Firestore (new device)
        final imported = await SyncService().fetchRemoteScans();
        if (!mounted) return;

        if (imported.isNotEmpty) {
          ref.read(scanHistoryProvider.notifier).mergeImported(imported);
          
          // Apply 7-day rule to the recovered remote data
          imported.sort((a, b) => b.date.compareTo(a.date));
          final lastScanDate = imported.first.date;
          final daysSince = DateTime.now().difference(lastScanDate).inDays;
          
          if (daysSince >= 7) {
            Navigator.of(context).pushReplacementNamed('/camera-scan');
          } else {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        } else {
          // No scans anywhere → go to camera scan
          Navigator.of(context).pushReplacementNamed('/camera-scan');
        }
      } else {
        if (!mounted) return;
        // Has local scans: check if 7 days have passed since last scan
        final lastScanDateStr = localScans.first['date'] as String;
        final lastScanDate = DateTime.parse(lastScanDateStr);
        final daysSince = DateTime.now().difference(lastScanDate).inDays;
        
        if (daysSince >= 7) {
          Navigator.of(context).pushReplacementNamed('/camera-scan');
        } else {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } catch (e) {
      debugPrint('_checkAuthAndRoute error: $e');
      // Fallback: if anything fails but user is logged in, go to auth to re-verify
      if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Video / Fallback Gradient
          _isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.background,
                        Color(0xFF1E0E3D),
                        Color(0xFF0B001A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

          // 2. Translucent Ambient Overlay (Lightened so video is visible)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withAlpha(50),
                  Colors.black.withAlpha(140),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Floating Content & Glassmorphism Card
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar Logo & Brand
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
                            color: Colors.white,
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

                    // Center Glassmorphic Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withAlpha(31),
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
                              // Glowing Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Main Tagline
                              Text(
                                'Chisel Your Face\nElevate Your Aura',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withAlpha(128),
                                      offset: const Offset(0, 2),
                                      blurRadius: 10,
                                    )
                                  ]
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
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Custom Interactive Button OR Loading Dots
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showAuthButton)
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withAlpha(102),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/auth');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CHISEL MY FACE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                ],
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 56,
                            child: _LoadingDots(),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Powered by Ai (1.0 Vision)',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white38,
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

/// Animated loading dots shown while auth check runs
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
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
            final opacity = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.2, 1.0);
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

