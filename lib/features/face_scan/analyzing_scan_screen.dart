import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_stats_provider.dart';
import 'scan_report_page.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/models/face_data_model.dart';
import '../../core/utils/face_analyzer_engine.dart';
import '../../core/providers/voice_guide_provider.dart';
import '../../shared/widgets/glass_container.dart';
import 'dart:io';
import 'dart:math' as math;

class AnalyzingScanScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const AnalyzingScanScreen({super.key, required this.imagePath});

  @override
  ConsumerState<AnalyzingScanScreen> createState() => _AnalyzingScanScreenState();
}

class _AnalyzingScanScreenState extends ConsumerState<AnalyzingScanScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  
  late Animation<double> _scanLineAnimation;

  int _currentStep = 0;
  String _statusText = 'Initializing Bio-Scan...';
  double _progress = 0.0;

  final List<Map<String, String>> _steps = [
    {'title': 'Analyzing Face', 'voice': 'I am scanning your facial features and checking for symmetry.'},
    {'title': 'Identifying Problems', 'voice': 'Identifying key areas for improvement in skin texture and structure.'},
    {'title': 'Creating Report', 'voice': 'Finalizing your facial data to generate a comprehensive report.'},
    {'title': 'Generating Solution', 'voice': 'Almost ready. I am creating a personalized growth plan tailored for you.'},
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    _scanLineController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _scanLineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut));
    
    _startAnalysisFlow();
  }

  Future<void> _startAnalysisFlow() async {
    // Start step progression
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _currentStep = i;
        _statusText = _steps[i]['title']!;
        _progress = (i + 1) / _steps.length;
      });

      // Speak step guidance
      ref.read(voiceGuideProvider.notifier).speak(_steps[i]['voice']!);

      // Wait for the step duration (approx 2.5s per step for a 10s total experience)
      await Future.delayed(const Duration(milliseconds: 2500));
    }

    // After all steps, process data and navigate
    _processAndNavigate();
  }

  Future<void> _processAndNavigate() async {
    // 1. Initialize detector
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);

    try {
      // 2. Load and process image
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception('No face detected in the image.');
      }

      // 3. Extract and Analyze Data
      // (Using a placeholder size for now, ideally we should get the image dimensions)
      final imageFile = File(widget.imagePath);
      final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());
      final imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      
      final faceData = FaceDataExtractor.extract(faces.first, imageSize);
      final analysisResult = FaceAnalyzerEngine.analyze(faceData);

      // 4. Update local state via Riverpod with REAL score
      final statsNotifier = ref.read(userStatsProvider.notifier);
      await statsNotifier.updateFaceScore(analysisResult.attractivenessScore.toInt());
      await statsNotifier.addCoins(25); // Award coins for face scanning
      await statsNotifier.consumeFreeScan();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ScanReportPage(
              result: analysisResult,
              imagePath: widget.imagePath,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
               return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during face analysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis Failed: $e')),
        );
        Navigator.pop(context); // Go back if it fails
      }
    } finally {
      faceDetector.close();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Kinetic Effects
          _buildBackgroundNebula(),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Gaming HUD Header
                  _buildHUDHeader(),
                  
                  const SizedBox(height: 40),
                  
                  // 2. Central Bio-Scanner HUD
                  _buildBioScannerHUD(),
                  
                  const SizedBox(height: 40),
                  
                  // 3. Status Display
                  _buildStatusHUD(),
                  
                  const SizedBox(height: 24),
                  
                  // 4. Progress bar (High tech style)
                  _buildTechProgressBar(),
                  
                  const SizedBox(height: 40),
                  
                  // 5. Sequential Step Progress (Glassmorphic)
                  _buildAnalysisSteps(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundNebula() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1 * _pulseController.value),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHUDHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: AppColors.secondary, size: 14),
            const SizedBox(width: 8),
            Text(
              'BIO-DATA DIAGNOSTIC',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 1, width: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.secondary.withValues(alpha: 0.5), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioScannerHUD() {
    return SizedBox(
      height: 320,
      width: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Target Ring
          _buildRotatingRing(300, 300, 1.0, AppColors.primary, 0.1),
          // Inner Target Ring
          _buildRotatingRing(240, 240, -1.5, AppColors.secondary, 0.2),
          
          // Image / Silhouette
          ClipRRect(
            borderRadius: BorderRadius.circular(150),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                        width: 220,
                        height: 220,
                      ),
                    ),
                  ),
                  
                  // Scanning Line Overlay
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, child) {
                      return Positioned(
                        top: 220 * (0.5 + 0.5 * _scanLineAnimation.value),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary,
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, AppColors.secondary, Colors.transparent],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Target HUD corners
          _buildHUDCorners(),
        ],
      ),
    );
  }

  Widget _buildRotatingRing(double w, double h, double speed, Color color, double opacity) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi * speed,
          child: Container(
            width: w, height: h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            child: CustomPaint(painter: RingPainter(color.withValues(alpha: opacity * 2))),
          ),
        );
      },
    );
  }

  Widget _buildHUDCorners() {
    return const SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _HUDCorner(0)),
          Positioned(top: 0, right: 0, child: _HUDCorner(1)),
          Positioned(bottom: 0, left: 0, child: _HUDCorner(2)),
          Positioned(bottom: 0, right: 0, child: _HUDCorner(3)),
        ],
      ),
    );
  }

  Widget _buildStatusHUD() {
    return Column(
      children: [
        Text(
          _statusText.toUpperCase(),
          style: AppTypography.displaySmall.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: [
              Shadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "ENCRYPTED CHANNEL ATTACHED",
          style: TextStyle(
            color: AppColors.secondary.withValues(alpha: 0.5),
            fontSize: 10,
            fontFamily: 'Courier',
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTechProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "${(_progress * 100).toInt()}%",
            style: const TextStyle(color: AppColors.secondary, fontFamily: 'Courier', fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSteps() {
    return Column(
      children: List.generate(_steps.length, (index) {
        final isVisible = index <= _currentStep;
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;
        
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isVisible ? 1.0 : 0.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            margin: EdgeInsets.only(bottom: isVisible ? 16 : 0),
            height: isVisible ? null : 0,
            child: _buildStepResult(
              _steps[index]['title']!,
              isActive: isActive,
              isDone: isDone,
              technicalDetail: _getTechnicalDetail(index),
            ),
          ),
        );
      }),
    );
  }

  String _getTechnicalDetail(int index) {
    switch (index) {
      case 0: return 'Landmarks: 68 points isolated';
      case 1: return 'Symmetry: 98.2% correlation';
      case 2: return 'Metrics: High-fidelity rendered';
      case 3: return 'Verdict: Finalizing roadmap';
      default: return '';
    }
  }
  
  Widget _buildStepResult(String title, {required bool isActive, required bool isDone, required String technicalDetail}) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      opacity: isDone ? 0.08 : (isActive ? 0.05 : 0.02),
      borderRadius: 16,
      borderOpacity: isDone ? 0.2 : (isActive ? 0.3 : 0.05),
      color: isDone ? AppColors.secondary : (isActive ? AppColors.primary : Colors.white),
      child: Row(
        children: [
          _buildStatusIndicator(isActive, isDone),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: isDone ? AppColors.secondary : (isActive ? Colors.white : Colors.white24),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                Text(
                  technicalDetail,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    color: isDone ? AppColors.secondary.withValues(alpha: 0.7) : Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.verified, color: AppColors.secondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isActive, bool isDone) {
    if (isDone) {
      return Container(
        width: 12, height: 12,
        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
      );
    }
    if (isActive) {
      return SizedBox(
        width: 12, height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2, 
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withValues(alpha: 0.8)),
        ),
      );
    }
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(border: Border.all(color: Colors.white10), shape: BoxShape.circle),
    );
  }
}

class RingPainter extends CustomPainter {
  final Color color;
  RingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw dashes
    for (int i = 0; i < 8; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * 45) * math.pi / 180,
        20 * math.pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _HUDCorner extends StatelessWidget {
  final int quadrant;
  const _HUDCorner(this.quadrant);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: (quadrant == 0 || quadrant == 1) ? const BorderSide(color: Colors.white24, width: 2) : BorderSide.none,
          bottom: (quadrant == 2 || quadrant == 3) ? const BorderSide(color: Colors.white24, width: 2) : BorderSide.none,
          left: (quadrant == 0 || quadrant == 2) ? const BorderSide(color: Colors.white24, width: 2) : BorderSide.none,
          right: (quadrant == 1 || quadrant == 3) ? const BorderSide(color: Colors.white24, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}
