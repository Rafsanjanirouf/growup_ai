import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../home/main_navigation_screen.dart';

class FaceScanAnalysisScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const FaceScanAnalysisScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<FaceScanAnalysisScreen> createState() =>
      _FaceScanAnalysisScreenState();
}

class _FaceScanAnalysisScreenState
    extends ConsumerState<FaceScanAnalysisScreen> {
  late Future<ScanResult> _analyzeFuture;

  @override
  void initState() {
    super.initState();
    _analyzeFuture = _performAnalysis();
  }

  Future<ScanResult> _performAnalysis() async {
    // Simulate scan analysis
    await Future.delayed(const Duration(seconds: 3));
    return ScanResult(
      overallScore: 7.8,
      skinHealth: 8.2,
      skinTone: 7.5,
      blemishes: 6.9,
      wrinkles: 8.0,
      asymmetry: 7.2,
      recommendations: [
        'Use SPF 50+ sunscreen daily',
        'Increase water intake for better hydration',
        'Consider retinol for fine lines',
        'Exfoliate 2x per week',
        'Use vitamin C serum',
      ],
      timestamp: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLow,
        elevation: 0,
        title: Text(
          'Scan Analysis',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<ScanResult>(
        future: _analyzeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildAnalyzingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen();
          }

          if (snapshot.hasData) {
            return _buildResultsScreen(snapshot.data!);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAnalyzingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.premiumGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation(AppColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Your Skin...',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Our AI is examining your skin health',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Analysis Failed',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen(ScanResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your Skin Score',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${result.overallScore.toStringAsFixed(1)}/10',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: result.overallScore / 10,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Detailed Metrics
          Text(
            'Detailed Analysis',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _MetricCard(
            label: 'Skin Health',
            score: result.skinHealth,
          ),
          _MetricCard(
            label: 'Skin Tone',
            score: result.skinTone,
          ),
          _MetricCard(
            label: 'Blemishes',
            score: result.blemishes,
          ),
          _MetricCard(
            label: 'Wrinkles',
            score: result.wrinkles,
          ),
          _MetricCard(
            label: 'Facial Symmetry',
            score: result.asymmetry,
          ),
          const SizedBox(height: 32),

          // Recommendations
          Text(
            'Personalized Recommendations',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...result.recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Go to Home',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double score;

  const _MetricCard({
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/10',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 6,
              backgroundColor: AppColors.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                score >= 7 ? AppColors.secondary : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanResult {
  final double overallScore;
  final double skinHealth;
  final double skinTone;
  final double blemishes;
  final double wrinkles;
  final double asymmetry;
  final List<String> recommendations;
  final DateTime timestamp;

  ScanResult({
    required this.overallScore,
    required this.skinHealth,
    required this.skinTone,
    required this.blemishes,
    required this.wrinkles,
    required this.asymmetry,
    required this.recommendations,
    required this.timestamp,
  });
}
