import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
import '../../core/services/backup_preference_service.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/config/app_languages.dart';
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
  String _selectedLanguage = 'English';

  // Delegate to shared AppLanguages config
  static List<Map<String, String>> get _languages => AppLanguages.all;

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

    // Load user's saved language (if any), otherwise detect device locale
    final savedLang = ref.read(userStateProvider).coachLanguage;
    if (savedLang.isNotEmpty && AppLanguages.all.any((l) => l['name'] == savedLang)) {
      _selectedLanguage = savedLang;
    } else {
      // Detect device locale and map to a supported language
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _selectedLanguage = AppLanguages.fromDeviceLocale(deviceLocale);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguagePicker();
    });
  }

  /// Shows a bottom sheet to pick the report language, then starts analysis.
  Future<void> _showLanguagePicker() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => _LanguagePickerSheet(
        selectedLanguage: _selectedLanguage,
        languages: _languages,
      ),
    );

    if (!mounted) return;

    if (chosen != null) {
      _selectedLanguage = chosen;
      // Persist the chosen language
      await ref.read(userStateProvider.notifier).updateLanguage(chosen);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final locale = AppLanguages.fullLocaleFor(chosen);
          await FirestoreService().updateUser(uid, {
            'language': chosen,
            'languageLocale': locale,
            'coach_language': chosen,
          });
        } catch (_) {}
      }
    }

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
          // Use the language selected from the picker (already updated in state)
          final String userLanguage = _selectedLanguage;

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
        try {
          await _storeScanResult(_demoData());
        } catch (fallbackErr) {
          debugPrint('Fallback store error: $fallbackErr');
        }
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
      // Free user — gate behind teaser / locked report screen
      Navigator.of(context).pushReplacementNamed('/locked-report');
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

    // New Comprehensive Metrics
    final faceShape = GeminiService.safeString(data['face_shape'], 'Oval');
    final faceSymmetry = GeminiService.safeDouble(data['face_symmetry'], 80.0);
    final skinHealthScore = GeminiService.safeDouble(data['skin_health_score'], 80.0);
    final acneDetection = GeminiService.safeString(data['acne_detection'], 'Clear');
    final faceAgeEstimation = (GeminiService.safeDouble(data['face_age_estimation'], 20.0)).toInt();
    final darkCircles = GeminiService.safeString(data['dark_circles'], 'None');
    final hairDensity = GeminiService.safeDouble(data['hair_density'], 80.0);
    final overallAiFaceScore = GeminiService.safeDouble(data['overall_ai_face_score'], overallScore);

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

    // ── 1. Upload Image to Storage OR Save Locally (Synchronous wait) ──────────
    final imageBackupEnabled = BackupPreferenceService().isBackupEnabled;
    String? finalImageUrl;

    if (imageBackupEnabled && widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      finalImageUrl = await FirestoreService().uploadImage(widget.imagePath!, userId, scanId);
    } else if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final fileName = 'local_scan_$scanId.webp';
        final savedFile = await File(widget.imagePath!).copy('${docsDir.path}/$fileName');
        finalImageUrl = savedFile.path;
      } catch (e) {
        debugPrint('Error saving local image: $e');
        finalImageUrl = widget.imagePath;
      }
    }

    // ── 2. Save full report directly to Firestore ─────────────────────────────
    await FirestoreService().saveScanRecord(
      userId: userId,
      scanId: scanId,
      scanDate: now,
      overallScore: overallScore,
      auraScore: auraScore,
      symmetryScore: symmetryScore,
      goldenRatioScore: goldenRatio,
      cutenessScore: cutenessScore,
      hotnessScore: hotnessScore,
      dominationScore: domScore,
      postureScore: postureScore,
      rating: rating,
      faceShape: faceShape,
      faceSymmetry: faceSymmetry,
      skinHealthScore: skinHealthScore,
      acneDetection: acneDetection,
      faceAgeEstimation: faceAgeEstimation,
      darkCircles: darkCircles,
      hairDensity: hairDensity,
      overallAiFaceScore: overallAiFaceScore,
      jawlineDetails: jawlineDetails,
      cheekboneDetails: cheekboneDetails,
      eyeDetails: eyeDetails,
      noseDetails: noseDetails,
      lipDetails: lipDetails,
      chinDetails: chinDetails,
      skinDetails: skinDetails,
      highlights: highlights,
      suggestions: suggestions,
      imageUrl: finalImageUrl,
      weekIndex: 0,
      imageBackupEnabled: imageBackupEnabled,
    );

    // ── 3. Fetch fresh state from Firestore ────────────────────────────────────
    if (mounted) {
      await ref.read(scanHistoryProvider.notifier).loadHistory();
    }

    // ── 4. Update local providers ──────────────────────────────────────────────
    await ref.read(userStateProvider.notifier).updateAuraScore(auraScore100);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('paywall_pending', true);

    final habits = GeminiService.parseRoutineJson(jsonEncode(data));
    if (habits.isNotEmpty) {
      await ref.read(habitProvider.notifier).replaceDynamicHabits(habits);
    }
  }

  Map<String, dynamic> _demoData() => {
        'aura_score': 68.5,
        'jawline_symmetry': 72,
        'skin_quality': 65,
        'overall_score': 70.0,
        
        // Comprehensive metrics fallback
        'face_shape': 'Diamond',
        'face_symmetry': 82.5,
        'skin_health_score': 78.0,
        'acne_detection': 'Mild',
        'face_age_estimation': 22,
        'dark_circles': 'Slight',
        'hair_density': 85.0,
        'overall_ai_face_score': 88.0,

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
    final progress = (_currentStep + 1) / _scanSteps.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ── Top label ────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'GROWUP AI ENGINE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.5,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Running Deep Face Analysis',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Face image + pulsing rings ────────────────────────────────
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow rings
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) => Container(
                            width: 200 + (_pulseAnimation.value * 40),
                            height: 200 + (_pulseAnimation.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.secondary.withAlpha(
                                    ((1.0 - _pulseAnimation.value) * 80).toInt()),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) => Container(
                            width: 200 + ((1.0 - _pulseAnimation.value) * 60),
                            height: 200 + ((1.0 - _pulseAnimation.value) * 60),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withAlpha(
                                    (_pulseAnimation.value * 60).toInt()),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        // Face image circle
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.secondary.withAlpha(120),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withAlpha(60),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: widget.imagePath != null
                                ? Image.file(
                                    File(widget.imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, _) => Image.asset(
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

                        // Laser scan line
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) => Positioned(
                            top: 10 + (_pulseAnimation.value * 148),
                            child: Container(
                              width: 168,
                              height: 3,
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
                                    color: AppTheme.secondary.withAlpha(180),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Overall progress bar ──────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Analysis Progress',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white38,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 6,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Animated steps list ───────────────────────────────────────
                Text(
                  'RUNNING MODULES',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.white24,
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _scanSteps.length,
                    itemBuilder: (context, idx) {
                      final isDone = idx < _currentStep;
                      final isActive = idx == _currentStep;
                      final isPending = idx > _currentStep;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: isPending ? 0.2 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.secondary.withAlpha(20)
                                : isDone
                                    ? Colors.white.withAlpha(6)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.secondary.withAlpha(80)
                                  : isDone
                                      ? AppTheme.primary.withAlpha(40)
                                      : Colors.white.withAlpha(10),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status icon
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isDone
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppTheme.primary,
                                        size: 20,
                                        key: ValueKey('done'),
                                      )
                                    : isActive
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            key: const ValueKey('active'),
                                            child: AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, _) => CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppTheme.secondary.withAlpha(
                                                      (150 + (_pulseAnimation.value * 105)).toInt()),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 20,
                                            height: 20,
                                            key: const ValueKey('pending'),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white12),
                                            ),
                                          ),
                              ),
                              const SizedBox(width: 12),

                              // Step text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _scanSteps[idx],
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                        color: isDone
                                            ? Colors.white60
                                            : isActive
                                                ? Colors.white
                                                : Colors.white30,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(height: 3),
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, _) => Text(
                                          'Processing...',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            color: AppTheme.secondary.withAlpha(
                                                (100 + (_pulseAnimation.value * 155)).toInt()),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isDone) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Complete ✓',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppTheme.primary.withAlpha(150),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Right badge
                              if (isDone)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'DONE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              if (isActive)
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, _) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withAlpha(
                                          (20 + (_pulseAnimation.value * 30).toInt())),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppTheme.secondary.withAlpha(60)),
                                    ),
                                    child: Text(
                                      'LIVE',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.secondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ── Bottom hint ────────────────────────────────────────────────
                Center(
                  child: Text(
                    'Please keep the app open during analysis',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Language Picker Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _LanguagePickerSheet extends StatefulWidget {
  final String selectedLanguage;
  final List<Map<String, String>> languages;

  const _LanguagePickerSheet({
    required this.selectedLanguage,
    required this.languages,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.secondary.withAlpha(60)),
                ),
                child: const Icon(Icons.translate_rounded, color: AppTheme.secondary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Language',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Choose language for your AI analysis',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Language Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.languages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final lang = widget.languages[index];
              final isSelected = _selected == lang['name'];
              return GestureDetector(
                onTap: () => setState(() => _selected = lang['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary.withAlpha(35)
                        : Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondary
                          : Colors.white.withAlpha(20),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.secondary.withAlpha(40),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lang['name']!,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.secondary : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              lang['native']!,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.white38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.secondary, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppTheme.primaryGradient,
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
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
                      'GENERATE REPORT IN',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selected,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
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
