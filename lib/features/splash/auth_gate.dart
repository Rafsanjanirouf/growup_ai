import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/user_provider.dart';
import '../../core/providers/scan_history_provider.dart';
import '../../core/providers/daily_progress_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/backup_preference_service.dart';
import '../../core/theme/app_theme.dart';
import '../scan/scan_detail_screen.dart';

/// Logic-only widget that handles auth checking, Firestore fetching,
/// provider syncing and final navigation.
/// It shows a minimal loading UI while working — the splash already played.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRoute();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Main Auth Check & Routing Logic ──────────────────────────────────────
  Future<void> _checkAuthAndRoute() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // ── NOT LOGGED IN → go to auth screen ───────────────────────────────────
    if (user == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
      return;
    }

    // ── LOGGED IN → init services ────────────────────────────────────────────
    try {
      await SubscriptionService().init(userId: user.uid);
    } catch (e) {
      debugPrint('SubscriptionService init error: $e');
    }

    // Background: push unsynced scans (fire and forget)
    SyncService().syncPendingScans();

    // ── Fetch user doc from Firestore ────────────────────────────────────────
    try {
      final db = FirebaseFirestore.instance;

      final doc = await db
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      // User doc doesn't exist yet → onboarding
      if (!doc.exists) {
        Navigator.of(context).pushReplacementNamed('/profile-setup');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // ── TEMPORARY: Inject Gift Subscription for specific UIDs ──────────────
      const giftUids = {
        'KdZcxQdzfIZrcmRXXxPQmHIDfXb2',
        'dDkC2Nf54WScE6RzAu3ieBO56Nt2',
      };
      if (giftUids.contains(user.uid)) {
        try {
          final subDocRef = db.collection('subscription').doc(user.uid);
          final subDoc = await subDocRef.get();
          if (!subDoc.exists ||
              subDoc.data()?['subscription_category'] != 'Gift') {
            debugPrint('Injecting Gift Subscription for ${user.uid}...');
            await subDocRef.set({
              'custom_subscription': true,
              'subscription_category': 'Gift',
              'custom_sub_start_date': Timestamp.now(),
              'custom_sub_end_date': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 365)),
              ),
            }, SetOptions(merge: true));
          }
        } catch (e) {
          debugPrint('Error injecting subscription override: $e');
        }
      }
      // ──────────────────────────────────────────────────────────────────────

      // ── Onboarding / Profile completion check ───────────────────────────
      final bool profileCompleted = data['profileCompleted'] ?? false;
      if (!profileCompleted) {
        final String fsName = data['display_name'] ?? '';
        final String fsGender = data['gender'] ?? '';
        if (fsName.isNotEmpty && fsGender.isNotEmpty) {
          // Existing user with basic profile info: sync basic info and send straight to goals/problems selection
          final int fsAge = data['age'] ?? 18;
          final double fsAuraScore =
              (data['aura_score'] as num?)?.toDouble() ?? 0.0;
          final String fsCoachLanguage = data['coach_language'] ?? 'English';

          final userNotifier = ref.read(userStateProvider.notifier);
          await userNotifier.updateProfile(
            name: fsName,
            age: fsAge,
            gender: fsGender,
          );
          await userNotifier.updateAuraScore(fsAuraScore);
          await userNotifier.updateLanguage(fsCoachLanguage);

          if (mounted) Navigator.of(context).pushReplacementNamed('/goals');
          return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/profile-setup');
        }
        return;
      }

      // ── Sync user profile from Firestore to local ──────────────────────────
      final String fsName = data['display_name'] ?? '';
      final int fsAge = data['age'] ?? 18;
      final String fsGender = data['gender'] ?? 'Male';
      final double fsAuraScore =
          (data['aura_score'] as num?)?.toDouble() ?? 0.0;
      final String fsCoachLanguage = data['coach_language'] ?? 'English';
      final String? morningTime = data['aura_morning_time'];
      final String? noonTime = data['aura_noon_time'];
      final String? eveningTime = data['aura_evening_time'];
      final String? nightTime = data['aura_night_time'];

      final List<String> fsGoals = List<String>.from(data['goals'] ?? []);
      final String fsSkinType = data['skinType'] ?? data['skin_type'] ?? 'Oily';
      final String fsBudget = data['budget'] ?? 'Basic';

      final userNotifier = ref.read(userStateProvider.notifier);
      await userNotifier.updateProfile(
        name: fsName,
        age: fsAge,
        gender: fsGender,
      );
      await userNotifier.updateGoals(fsGoals);
      await userNotifier.updateLifestyle(
        skinType: fsSkinType,
        budget: fsBudget,
      );
      await userNotifier.completeOnboarding();
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
          final mapped = rawProgress
              .map(
                (d) => DailyProgress(
                  dateKey: d['date_key'] ?? '',
                  date: DateTime.parse(d['date_key']),
                  completed: d['completed_count'] ?? 0,
                  total: d['total_count'] ?? 9,
                ),
              )
              .toList();
          await ref
              .read(dailyProgressProvider.notifier)
              .syncFromFirestore(mapped);
        }
      } catch (e) {
        debugPrint('Failed to sync daily progress: $e');
      }

      // ── Backup consent not shown → consent screen ──────────────────────────
      if (!BackupPreferenceService().hasShownConsent) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/backup-consent');
        }
        return;
      }

      // ── Determine Pro status ───────────────────────────────────────────────
      bool isPro = false;
      try {
        isPro = await SubscriptionService().isProEntitled();
      } catch (e) {
        debugPrint('RevenueCat check error: $e');
      }

      if (!isPro) {
        // Check custom subscription override from Firestore
        try {
          final subDoc = await db
              .collection('subscription')
              .doc(user.uid)
              .get();
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
                  debugPrint(
                    'Custom subscription expired on ${endDateRaw.toDate()}',
                  );
                  try {
                    await subDoc.reference.update({
                      'custom_subscription': false,
                    });
                  } catch (_) {}
                }
              } else {
                debugPrint(
                  'Custom subscription: no valid end date → assumed lifetime/gift',
                );
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

      // ── NOT PRO → Paywall ──────────────────────────────────────────────────
      if (!isPro) {
        Navigator.of(context).pushReplacementNamed('/paywall');
        return;
      }

      // ── PRO: handle paywall_pending flag ───────────────────────────────────
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScanDetailScreen(
                    scan: latestScan,
                    previousScan: previousScan,
                  ),
                ),
              );
            }
          } else {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        }
        return;
      }

      // ── PRO: Regular navigation based on scan history ──────────────────────
      final localScans = await LocalDbService().getAllScans(user.uid);

      if (localScans.isEmpty) {
        // No local scans — try recovering from Firestore (new device)
        final imported = await SyncService().fetchRemoteScans();
        if (!mounted) return;

        if (imported.isNotEmpty) {
          ref.read(scanHistoryProvider.notifier).mergeImported(imported);

          imported.sort((a, b) => b.date.compareTo(a.date));
          final lastScanDate = imported.first.date;
          final daysSince = DateTime.now().difference(lastScanDate).inDays;

          if (daysSince >= 7) {
            Navigator.of(context).pushReplacementNamed('/camera-scan');
          } else {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/camera-scan');
        }
      } else {
        if (!mounted) return;
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
      debugPrint('AuthGate routing error: $e');
      // Fallback: anything fails → send to auth
      if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Premium Animated Orb ────────────────────────────────────────
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80 + (_pulseAnimation.value * 20),
                    height: 80 + (_pulseAnimation.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary.withAlpha(
                        (_pulseAnimation.value * 20).toInt(),
                      ),
                      border: Border.all(
                        color: AppTheme.secondary.withAlpha(
                          (100 + _pulseAnimation.value * 100).toInt(),
                        ),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withAlpha(
                            (_pulseAnimation.value * 80).toInt(),
                          ),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.blur_on_rounded,
                        color: AppTheme.secondary.withAlpha(
                          (150 + _pulseAnimation.value * 105).toInt(),
                        ),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // ── Text ────────────────────────────────────────────────────────
              Text(
                'SYNCING DATA',
                style: GoogleFonts.outfit(
                  color: AppTheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Text(
                  'Loading your profile securely...',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withAlpha(
                      (100 + _pulseAnimation.value * 100).toInt(),
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
