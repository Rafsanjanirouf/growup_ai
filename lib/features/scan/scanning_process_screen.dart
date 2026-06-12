import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/ml_kit_scoring_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/scan_history_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/services/subscription_service.dart';
import 'scan_detail_screen.dart';

class ScanningProcessScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  const ScanningProcessScreen({super.key, this.imagePath});

  @override
  ConsumerState<ScanningProcessScreen> createState() =>
      _ScanningProcessScreenState();
}

class _ScanningProcessScreenState extends ConsumerState<ScanningProcessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;

  final List<String> _scanSteps = [
    'Detecting facial boundaries...',
    'Analyzing Jawline symmetry percentage...',
    'Checking skin tone texture & blemishes...',
    'Calculating eye alignment & posture index...',
    'Generating Current Aura Score...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runAnalysis();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    // Animate step labels while analyzing
    final stepTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_currentStep < _scanSteps.length - 1) {
        setState(() => _currentStep++);
      }
    });

    try {
      Map<String, dynamic> result;

      if (widget.imagePath != null) {
        // 1. Give the UI a moment to show "Analyzing"
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // 2. Perform offline local ML Kit face scoring
        final mlKitService = MLKitScoringService();
        result = await mlKitService.analyzeFace(widget.imagePath!);
        mlKitService.dispose();

        // 3. Send image and ML Kit scores to Gemini for deep diagnostics (10+ reports)
        try {
          String userLanguage = ref.read(userStateProvider).coachLanguage;

          final geminiData = await GeminiService.generateAnalytics(widget.imagePath!, result, language: userLanguage);
          result['analytics'] = geminiData['analytics'];
          result['morning_routine'] = geminiData['morning_routine'];
          result['noon_routine'] = geminiData['noon_routine'];
          result['evening_routine'] = geminiData['evening_routine'];
          result['night_routine'] = geminiData['night_routine'];
        } catch (geminiErr) {
          debugPrint('Gemini analytics failed: \$geminiErr');
          // Graceful fallback if Gemini fails
        }
      } else {
        // Fallback demo data when no image
        result = _demoData();
      }

      stepTimer.cancel();
      if (!mounted) return;
      setState(() => _currentStep = _scanSteps.length - 1);

      // Store scan record
      await _storeScanResult(result);

      // ── Revenue check: Pro users skip paywall ─────────────────────────────
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) await _navigateAfterScan();
      }
    } catch (e) {
      stepTimer.cancel();
      debugPrint('Analysis error: $e');
      if (mounted) {
        // Even on error, save demo data and proceed
        await _storeScanResult(_demoData());
        if (mounted) await _navigateAfterScan();
      }
    }
  }

  /// Check RevenueCat entitlement after scan.
  /// Pro → ScanDetailScreen directly.
  /// Free → Paywall (subscription gate).
  Future<void> _navigateAfterScan() async {
    bool isPro = false;
    try {
      isPro = await SubscriptionService().isProEntitled();
    } catch (e) {
      debugPrint('_navigateAfterScan: entitlement check failed: $e');
    }

    if (!mounted) return;

    if (isPro) {
      // Pro user — show scan result immediately, skip paywall
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('paywall_pending', false);

      final scanList = ref.read(scanHistoryProvider);
      if (scanList.isNotEmpty && mounted) {
        final latestScan = scanList.first;
        final previousScan = scanList.length > 1 ? scanList[1] : null;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ScanDetailScreen(
              scan: latestScan,
              previousScan: previousScan,
            ),
          ),
        );
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      // Free user — gate behind paywall
      Navigator.of(context).pushReplacementNamed('/paywall');
    }
  }

  // ML Kit Scoring has replaced Gemini API
  // Future<Map<String, dynamic>> _analyzeWithGemini(String imagePath) ...

  Future<void> _storeScanResult(Map<String, dynamic> data) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'anonymous';
    final scanId = const Uuid().v4();
    final now = DateTime.now();

    // ── Extract all schema fields with safe fallbacks ─────────────────────────
    final comp = GeminiService.safeMap(data['comprehensiveAnalysis']);
    final isMlKit = comp.isNotEmpty;

    final overallScore    = GeminiService.safeDouble(isMlKit ? comp['overallBeautyScore'] : data['overall_score'], 65.0);
    final auraScore       = GeminiService.safeDouble(isMlKit ? comp['overallBeautyScore'] : data['aura_score'], 6.5);
    final symmetryScore   = GeminiService.safeDouble(isMlKit ? comp['overallSymmetry'] : data['symmetry_score'], 65.0);
    final goldenRatio     = GeminiService.safeDouble(isMlKit ? comp['goldenRatioScore'] : data['golden_ratio_score'], 65.0);
    final cutenessScore   = GeminiService.safeDouble(isMlKit ? comp['faceShapeScore'] : data['cuteness_score'], 65.0);
    final hotnessScore    = GeminiService.safeDouble(isMlKit ? comp['hotScore'] : data['hotness_score'], 65.0);
    final domScore        = GeminiService.safeDouble(isMlKit ? comp['masculinityScore'] : data['domination_score'], 65.0);
    final postureScore    = GeminiService.safeDouble(data['posture_score'], 65.0);
    final rating          = GeminiService.safeString(isMlKit ? comp['beautyCategory'] : data['rating'], ScanRecord.computeRating(overallScore));

    final jawlineDetails   = GeminiService.safeMap(data['jawline_details']);
    final cheekboneDetails = GeminiService.safeMap(data['cheekbone_details']);
    final eyeDetails       = GeminiService.safeMap(data['eye_details']);
    final noseDetails      = GeminiService.safeMap(data['nose_details']);
    final lipDetails       = GeminiService.safeMap(data['lip_details']);
    final chinDetails      = GeminiService.safeMap(data['chin_details']);
    
    // For skin, MLKit has skinTexture and skinSmooth
    final skinTexture      = GeminiService.safeDouble(comp['skinTexture'], 65.0);
    final skinDetails      = isMlKit ? {'texture': skinTexture} : GeminiService.safeMap(data['skin_details']);
    
    // For eye, MLKit has eyeSymmetry
    final eyeSymmetryScore = GeminiService.safeDouble(comp['eyeSymmetry'], 65.0);
    if (isMlKit) eyeDetails['alertness'] = eyeSymmetryScore;

    final highlights  = GeminiService.safeStringList(isMlKit ? comp['strengths'] : data['highlights']);
    final suggestions = GeminiService.safeStringList(isMlKit ? comp['improvements'] : data['suggestions']);

    // User requested Aura Score to be the Overall average score
    final auraScore100 = overallScore.clamp(0.0, 100.0);

    // Build the full data map to store alongside local record
    // so SyncService can push a complete payload to Firestore later.
    final fullData = <String, dynamic>{
      ...data,
      'overall_score':     overallScore,
      'aura_score':        auraScore,
      'symmetry_score':    symmetryScore,
      'golden_ratio_score': goldenRatio,
      'cuteness_score':    cutenessScore,
      'hotness_score':     hotnessScore,
      'domination_score':  domScore,
      'posture_score':     postureScore,
      'rating':            rating,
      'highlights':        highlights,
      'suggestions':       suggestions,
      'skin_details':      skinDetails,
      'eye_details':       eyeDetails,
    };

    // ── 1. Save to LOCAL SQLite immediately (no network needed) ───────────────
    final localRecord = ScanRecord(
      id:           scanId,
      date:         now,
      auraScore:    auraScore100,
      jawlineScore: symmetryScore,
      skinScore:    GeminiService.safeDouble(skinDetails['texture'], 65.0),
      eyeScore:     GeminiService.safeDouble(eyeDetails['alertness'], 65.0),
      postureScore: postureScore,
      rating:       rating,
      highlights:   highlights.isNotEmpty ? highlights : ['Analysis complete'],
      imageUrl:     widget.imagePath, // Keep local path locally
      isSynced:     false,
    );

    await ref.read(scanHistoryProvider.notifier).addScan(
          localRecord,
          fullData: fullData,
        );
    await ref.read(userStateProvider.notifier).updateAuraScore(auraScore100);
    // Note: streak is managed exclusively by checkAndUpdateStreak() on app open (once per day).

    // ── 2. Set paywall_pending flag ───────────────────────────────────────────
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('paywall_pending', true);

    // ── 3. Save dynamic habits ────────────────────────────────────────────────
    final habits = GeminiService.parseRoutineJson(jsonEncode(data));
    if (habits.isNotEmpty) {
      await ref.read(habitProvider.notifier).replaceDynamicHabits(habits);
    }

    // ── 4. Background: upload image + Firestore sync (fire & forget) ──────────
    _backgroundSyncScan(
      userId:          userId,
      scanId:          scanId,
      scanDate:        now,
      overallScore:    overallScore,
      auraScore:       auraScore,
      symmetryScore:   symmetryScore,
      goldenRatio:     goldenRatio,
      cutenessScore:   cutenessScore,
      hotnessScore:    hotnessScore,
      domScore:        domScore,
      postureScore:    postureScore,
      rating:          rating,
      jawlineDetails:  jawlineDetails,
      cheekboneDetails: cheekboneDetails,
      eyeDetails:      eyeDetails,
      noseDetails:     noseDetails,
      lipDetails:      lipDetails,
      chinDetails:     chinDetails,
      skinDetails:     skinDetails,
      highlights:      highlights,
      suggestions:     suggestions,
    );
  }

  /// Fire-and-forget background task: push
  /// the full scan record to Firestore and mark local DB as synced.
  Future<void> _backgroundSyncScan({
    required String userId,
    required String scanId,
    required DateTime scanDate,
    required double overallScore,
    required double auraScore,
    required double symmetryScore,
    required double goldenRatio,
    required double cutenessScore,
    required double hotnessScore,
    required double domScore,
    required double postureScore,
    required String rating,
    required Map<String, dynamic> jawlineDetails,
    required Map<String, dynamic> cheekboneDetails,
    required Map<String, dynamic> eyeDetails,
    required Map<String, dynamic> noseDetails,
    required Map<String, dynamic> lipDetails,
    required Map<String, dynamic> chinDetails,
    required Map<String, dynamic> skinDetails,
    required List<String> highlights,
    required List<String> suggestions,
  }) async {
    try {
      await SyncService().syncPendingScans();
      debugPrint('_backgroundSyncScan: scan $scanId sync delegated to SyncService ✓');
      
      // Refresh the provider so the UI picks up the new Firebase Storage URL
      if (mounted) {
        await ref.read(scanHistoryProvider.notifier).loadHistory();
      }
    } catch (e) {
      debugPrint('_backgroundSyncScan: error: $e');
    }
  }

  Map<String, dynamic> _demoData() => {
        'aura_score': 68.5,
        'jawline_symmetry': 72,
        'skin_quality': 65,
        'hair_density': 80,
        'issues': [
          'Mild skin blemishes detected',
          'Slight jawline asymmetry',
        ],
        'morning_routine': [
          {'title': 'Hydration Kickstart 💧', 'desc': 'Drink 2 large glasses of warm water.'},
        ],
        'afternoon_routine': [
          {'title': 'Mewing Session 👅', 'desc': 'Press tongue to roof of mouth for 15 min.'},
        ],
        'night_routine': [
          {'title': 'Night Cleanse 🌌', 'desc': 'Cleanse face before bed.'},
        ],
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AURA ANALYZER ENGINE',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Central pulsing face image
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ClipOval(
                        child: widget.imagePath != null
                            ? Image.file(
                                File(widget.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Image.asset(
                                  'assets/image/avater_image.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/image/avater_image.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    // Pulsing ring 1
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Container(
                        width: 220 + (_pulseAnimation.value * 50),
                        height: 220 + (_pulseAnimation.value * 50),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(
                                ((1.0 - _pulseAnimation.value) * 128).toInt()),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),

                    // Pulsing ring 2
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Container(
                        width: 220 + ((1.0 - _pulseAnimation.value) * 80),
                        height: 220 + ((1.0 - _pulseAnimation.value) * 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.secondary.withAlpha(
                                (_pulseAnimation.value * 100).toInt()),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Scanning laser line
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Positioned(
                        top: 20 + (_pulseAnimation.value * 180),
                        child: Container(
                          width: 240,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.secondary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withAlpha(200),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // Step labels + dots
                SizedBox(
                  height: 80,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _scanSteps[_currentStep],
                          key: ValueKey(_currentStep),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_scanSteps.length, (idx) {
                          final isCurrent = idx == _currentStep;
                          final isPast = idx < _currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isCurrent ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isCurrent
                                  ? AppTheme.secondary
                                  : isPast
                                      ? AppTheme.primary
                                      : Colors.white12,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
