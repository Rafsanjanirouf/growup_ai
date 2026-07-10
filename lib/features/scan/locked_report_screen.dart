import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/exit_survey_dialog.dart';

class LockedReportScreen extends ConsumerStatefulWidget {
  const LockedReportScreen({super.key});

  @override
  ConsumerState<LockedReportScreen> createState() => _LockedReportScreenState();
}

class _LockedReportScreenState extends ConsumerState<LockedReportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _aiTeaser;
  bool _isLoadingTeaser = true;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeaser();
    });
  }

  Future<void> _loadTeaser() async {
    final userState = ref.read(userStateProvider);
    final language = userState.coachLanguage.isNotEmpty ? userState.coachLanguage : 'English';
    
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'ai_teaser_$language';
    final cachedTeaser = prefs.getString(cacheKey);
    
    if (cachedTeaser != null && cachedTeaser.isNotEmpty) {
      if (mounted) {
        setState(() {
          _aiTeaser = cachedTeaser;
          _isLoadingTeaser = false;
        });
      }
      return;
    }

    final teaser = await GeminiService.generateTeaserInsight(
      auraScore: userState.auraScore,
      goals: userState.goals,
      language: language,
    );
    
    await prefs.setString(cacheKey, teaser);

    if (mounted) {
      setState(() {
        _aiTeaser = teaser;
        _isLoadingTeaser = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlockTapped() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasShown = prefs.getBool('has_shown_feature_carousel') ?? false;
    
    if (!hasShown) {
      await prefs.setBool('has_shown_feature_carousel', true);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const FeatureCarouselBottomSheet(),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushNamed('/paywall');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userStateProvider);
    double normalizedScore = userState.auraScore;
    if (normalizedScore > 0 && normalizedScore <= 10) {
      normalizedScore = normalizedScore * 10;
    }
    final currentAura = normalizedScore > 0 ? normalizedScore.toStringAsFixed(1) : '??';
    final potentialAura = normalizedScore > 0 ? (normalizedScore + 3.8).clamp(0, 99.5).toStringAsFixed(1) : '98.5';

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => const ExitSurveyDialog(
            collectionName: 'prememership_complain',
          ),
        );

        if (shouldPop == true) {
          setState(() {
            _canPop = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              }
            }
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Report',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleUnlockTapped,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.secondary.withAlpha(100)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock, color: AppTheme.secondary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PRO',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Current GrowUp AI vs Potential Score
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Current GrowUp AI
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.textSecondary.withAlpha(40),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.4, 1.0],
                                ),
                                border: Border.all(
                                  color: AppTheme.textSecondary.withAlpha(20),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'CURRENT',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2.0,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentAura,
                                      style: GoogleFonts.outfit(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white70,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      '/100',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Potential GrowUp AI
                            RepaintBoundary(
                              child: ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      AppTheme.primaryGlow,
                                      Colors.transparent,
                                    ],
                                    stops: [0.4, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(50),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'POTENTIAL',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.0,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        potentialAura,
                                        style: GoogleFonts.outfit(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        '/100',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Psychological Teaser Data
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'AI Overview',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: _isLoadingTeaser
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(color: AppTheme.primary),
                                    ),
                                  )
                                : Text(
                                    _aiTeaser ?? 'Unlock PRO to reveal your full potential...',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: Colors.white,
                                      height: 1.6,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Blurred Detailed Reports
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comprehensive Analysis',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLockedBarChart(),
                          const SizedBox(height: 16),
                          _buildLockedGridDetails(),
                          const SizedBox(height: 16),
                          _buildLockedProgressBars(),
                          const SizedBox(height: 16),
                          _buildLockedMicroExpressions(),
                          const SizedBox(height: 16),
                          _buildLockedAIRecommendations(),
                          const SizedBox(height: 120), // Padding for bottom button
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom Gradient and Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.bg.withValues(alpha: 0.0),
                        AppTheme.bg.withValues(alpha: 0.9),
                        AppTheme.bg,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppTheme.gradientAccent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleUnlockTapped,
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppTheme.bg, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'UNLOCK FULL POTENTIAL',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.bg,
                                    letterSpacing: 1.2,
                                  ),
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
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLockedBarChart() {
    final List<double> heights = [40, 50, 45, 60, 75, 85, 100];
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GrowUp AI Projection', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('+12% Growth', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: heights.map((h) => Container(
                width: 24,
                height: h,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => Text(d, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12))).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildLockedProgressBars() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skin Health Analysis', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildProgressBar('Acne Clearing', 0.95, AppTheme.primary),
          const SizedBox(height: 12),
          _buildProgressBar('Hydration', 0.70, Colors.blue),
          const SizedBox(height: 12),
          _buildProgressBar('Even Texture', 0.85, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
            Text('${(percent * 100).toInt()}%', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedGridDetails() {
    final features = [
      {'title': 'Face Shape', 'val': 'Diamond'},
      {'title': 'Symmetry', 'val': '88%'},
      {'title': 'Jawline', 'val': 'Defined'},
      {'title': 'Canthal Tilt', 'val': 'Positive'},
      {'title': 'Face Age', 'val': '22 yrs'},
      {'title': 'Hair Density', 'val': 'High'},
    ];
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Facial Geometry', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(features[index]['title']!, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(features[index]['val']!, style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLockedMicroExpressions() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Micro-Expression Analysis', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildProgressBar('Confidence', 0.88, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildProgressBar('Approachability', 0.76, Colors.lightBlueAccent),
          const SizedBox(height: 12),
          _buildProgressBar('Intensity', 0.92, Colors.deepOrangeAccent),
        ],
      ),
    );
  }

  Widget _buildLockedAIRecommendations() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('AI Directives', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipRow(Icons.face_retouching_natural, 'Skincare Routine Match: 98%'),
          const SizedBox(height: 12),
          _buildTipRow(Icons.content_cut, 'Optimal Hairstyle: Textured Fringe'),
          const SizedBox(height: 12),
          _buildTipRow(Icons.fitness_center, 'Neck/Jaw Posture Fix Required'),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14))),
      ],
    );
  }

  Widget _buildLockedContainer({required Widget child}) {
    return GestureDetector(
      onTap: _handleUnlockTapped,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          children: [
            // Blurred Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: child,
                ),
              ),
            ),
            // Lock Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PRO EXCLUSIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white70,
                        ),
                      )
                    ],
                  ),
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

class FeatureCarouselBottomSheet extends StatefulWidget {
  const FeatureCarouselBottomSheet({super.key});

  @override
  State<FeatureCarouselBottomSheet> createState() => _FeatureCarouselBottomSheetState();
}

class _FeatureCarouselBottomSheetState extends State<FeatureCarouselBottomSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _features = [
    {
      'image': 'https://play-lh.googleusercontent.com/CRrc_hMI-jN4EZDGRLvH3s3kWsBE6Fv3zuqOIcmKxVqg_EWTA10Actygp2ftWzTilZixg1RrfLJcWNwJC2PuUQ',
      'isNetworkImage': true,
      'icon': Icons.analytics_rounded,
      'color': const Color(0xFF4FC3F7), // Light Blue
      'title': 'Weekly AI Scan Report',
      'desc': 'Track your physical improvements with extreme precision.',
      'bullets': [
        'Detailed geometric face analysis',
        'Symmetry & skin health tracking',
        'Compare past vs current photos'
      ]
    },
    {
      'image': 'https://play-lh.googleusercontent.com/TyGgacr1ccG1QZCt4sXUsWmvSblYPMr1yf1PeKHUZR7lG0IY0s_QabMS9a7b-_sygw6m-FyjvqvJekI6uuMpjQ',
      'isNetworkImage': true,
      'icon': Icons.dashboard_rounded,
      'color': const Color(0xFFFFB74D), // Orange
      'title': 'Pro Dashboard',
      'desc': 'Your ultimate lookmaxxing command center.',
      'bullets': [
        'Track your overall progress',
        'Quick access to all tools',
        'Monitor habit streaks'
      ]
    },
    {
      'image': 'https://play-lh.googleusercontent.com/LsxQAooLeQk6uRv5yDNVRQTPilCE4xwj4_pqdnFn6_K3huhDydYTzK_pwIE-sATPaxD1xPdeAjirlYuZ7Wsl_A',
      'isNetworkImage': true,
      'icon': Icons.task_alt_rounded,
      'color': const Color(0xFF81C784), // Green
      'title': 'Daily Tasks',
      'desc': 'Step-by-step routines to maximize your aura.',
      'bullets': [
        'Morning & Night skincare regimens',
        'Custom mewing & posture exercises',
        'Diet & hydration tracking'
      ]
    },
    {
      'image': 'https://play-lh.googleusercontent.com/I2KiUxZmmfIuGLJaBXtMOVzo4cm63mE7Vse7xxy1NnKQg7Uaz53xX5PVfLgaV7iDdsWkZGbDevXSqCMrJQQF',
      'isNetworkImage': true,
      'icon': Icons.checkroom_rounded,
      'color': const Color(0xFF4DB6AC), // Teal
      'title': 'AI Outfit Generator',
      'desc': 'Never struggle with what to wear. Get elite styling advice.',
      'bullets': [
        'Upload photo for instant styling',
        'Color palette recommendations',
        'Casual, Formal & Traditional fits'
      ]
    },
    {
      'image': 'https://play-lh.googleusercontent.com/3R23NQFItoFuzaitfsUh4JwJlzw4DlA4HLpUHsS72h6CDpZYh462aWgdyZrkXAcIgFDyWWMCTYipG3x1McIb',
      'isNetworkImage': true,
      'icon': Icons.face_retouching_natural_rounded,
      'color': const Color(0xFFF06292), // Pink
      'title': 'AI Hairstyle Generator',
      'desc': 'Discover the haircut that mathematically enhances your face.',
      'bullets': [
        'Face-shape matching algorithms',
        'Top 4 personalized styles',
        'Styling & maintenance advice'
      ]
    },
    {
      'image': 'https://play-lh.googleusercontent.com/kZbxOxRfzZuZDM1_SK9WVOB_AgBVYSeP5WT5yOpcas5OwhVEdTyh_XZOL1_re3mZN-zqFN47hixR18fZE4ln',
      'isNetworkImage': true,
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFBA68C8), // Purple
      'title': '24/7 AI Coach',
      'desc': 'Your personal aesthetics expert available anytime, anywhere.',
      'bullets': [
        'Ask anything about grooming',
        'Get tailored lookmaxxing advice',
        'Unlimited chat & support'
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height, // Full screen
      color: Colors.black, // Fallback background
      child: PageView.builder(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
            _isExpanded = false; // Reset expansion on page turn
          });
        },
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          final color = feature['color'] as Color;
          
          return Stack(
            children: [
              // 1. Full Screen Background Image
              Positioned.fill(
                child: feature['isNetworkImage']
                    ? Image.network(
                        feature['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: AppTheme.surface),
                      )
                    : Image.asset(
                        feature['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: AppTheme.surface),
                      ),
              ),

              // 2. Gradients for Text Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(200), // Top gradient for Title
                        Colors.transparent,          // Middle clear
                        Colors.transparent,
                        Colors.black.withAlpha(220), // Bottom gradient for Text
                      ],
                      stops: const [0.0, 0.2, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Top Title and Close Button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(feature['icon'], color: color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature['title'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withAlpha(150),
                                        blurRadius: 8,
                                      )
                                    ]
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Bottom Details & See More Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated details section
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded
                              ? Container(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        feature['desc'],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: (feature['bullets'] as List<String>).map((bullet) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: color, size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    bullet,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 15,
                                                      color: Colors.white70,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        
                        // See More / See Less Toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'See Less' : 'See More',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Dot Indicators & Continue Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(
                                _features.length,
                                (dotIndex) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 6,
                                  width: _currentPage == dotIndex ? 24 : 6,
                                  decoration: BoxDecoration(
                                    color: _currentPage == dotIndex ? color : Colors.white24,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            
                            // NEXT / UNLOCK PRO Button
                            GestureDetector(
                              onTap: () {
                                if (_currentPage < _features.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  Navigator.pop(context);
                                  Navigator.of(context).pushNamed('/paywall');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withAlpha(100),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _currentPage < _features.length - 1 ? 'NEXT' : 'UNLOCK PRO',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
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
          );
        },
      ),
    );
  }
}
