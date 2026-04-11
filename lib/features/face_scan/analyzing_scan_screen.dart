import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_stats_provider.dart';
import 'face_score_screen.dart';
import '../../core/widgets/app_header_fixed.dart';

class AnalyzingScanScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const AnalyzingScanScreen({super.key, required this.imagePath});

  @override
  ConsumerState<AnalyzingScanScreen> createState() => _AnalyzingScanScreenState();
}

class _AnalyzingScanScreenState extends ConsumerState<AnalyzingScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    _processAndNavigate();
  }

  Future<void> _processAndNavigate() async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // Calculate real points/score locally
    final random = Random();
    // Scoring logic: Generate a score between 70 and 95 for Day 1
    final newScore = 70 + random.nextInt(26);
    
    // Update local state via Riverpod
    final statsNotifier = ref.read(userStatsProvider.notifier);
    await statsNotifier.updateFaceScore(newScore);
    await statsNotifier.addCoins(15); // Award coins for scanning
    await statsNotifier.consumeFreeScan();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const FaceScoreScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'GROWUP AI',
        showBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Center Graph
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   AnimatedBuilder(
                     animation: _rotationController,
                     builder: (context, child) {
                       return Transform.rotate(
                         angle: _rotationController.value * 2 * 3.14159,
                         child: Container(
                           width: 250, height: 250,
                           decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2)),
                         ),
                       );
                     }
                   ),
                   AnimatedBuilder(
                     animation: _rotationController,
                     builder: (context, child) {
                       return Transform.rotate(
                         angle: -(_rotationController.value * 2 * 3.14159), // reverse
                         child: Container(
                           width: 200, height: 200,
                           decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1)),
                         ),
                       );
                     }
                   ),
                   // Central Icon glow
                   Container(
                     width: 120, height: 120,
                     decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 40)]),
                     child: const Icon(Icons.face, size: 60, color: AppColors.secondary),
                   )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Plus Jakarta Sans'),
                children: [
                  TextSpan(text: 'Analyzing Your ', style: TextStyle(color: AppColors.onSurface)),
                  TextSpan(text: 'Features...', style: TextStyle(color: AppColors.secondary)),
                ]
              )
            ),
            const SizedBox(height: 24),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                backgroundColor: AppColors.surfaceHighest,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 32),
            
            // Checklists
            _buildCheckmark('Detecting Landmarks...', 'Mapping complete', true),
            const SizedBox(height: 16),
            _buildCheckmark('Analyzing Skin...', 'Scanning complete', false),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCheckmark(String title, String subtitle, bool isDone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: isDone ? AppColors.secondary : AppColors.primary, width: 2)),
      ),
      child: Row(
        children: [
           Icon(isDone ? Icons.face_5 : Icons.texture, color: isDone ? AppColors.secondary : AppColors.primary),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                 Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
               ],
             ),
           ),
           if (isDone)
             const Icon(Icons.check_circle, color: AppColors.secondary, size: 20)
           else
             const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
        ],
      ),
    );
  }
}
