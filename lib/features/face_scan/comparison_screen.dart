import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/face_analyzer_engine.dart';

class ComparisonScreen extends StatelessWidget {
  final FaceAnalysisResult scanA;
  final FaceAnalysisResult scanB;
  final String imageA;
  final String imageB;

  const ComparisonScreen({
    super.key,
    required this.scanA,
    required this.scanB,
    required this.imageA,
    required this.imageB,
  });

  @override
  Widget build(BuildContext context) {
    // Logic: B is newer, A is older
    final overallDelta = scanB.attractivenessScore - scanA.attractivenessScore;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER (Matching App UI) =====
            _buildHeader(context),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Image Comparison Hero
                  _buildImageComparison(),

                  const SizedBox(height: 32),

                  // 2. Growth Overview Card
                  _buildGrowthSummary(overallDelta),

                  const SizedBox(height: 32),

                  // 3. Detailed Metrics Comparison
                  _buildComparisonTable(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'PROGRESS COMPARISON',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildImageComparison() {
    return Row(
      children: [
        Expanded(child: _buildComparisonFace(imageA, 'PREVIOUS')),
        const SizedBox(width: 12),
        Expanded(child: _buildComparisonFace(imageB, 'CURRENT')),
      ],
    );
  }

  Widget _buildComparisonFace(String url, String label) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: label == 'CURRENT' ? AppColors.secondary : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthSummary(double delta) {
    final isPositive = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isPositive ? AppColors.secondary : AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Text(
                '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? AppColors.secondary : AppColors.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'NET GROWTH DETECTED',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white38,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'METRIC BREAKDOWN',
          style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 2, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        _buildMetricRow('Overall Score', scanA.attractivenessScore, scanB.attractivenessScore),
        _buildMetricRow('Symmetry', scanA.overallSymmetry, scanB.overallSymmetry),
        _buildMetricRow('Skin Health', scanA.skinSmooth, scanB.skinSmooth),
        _buildMetricRow('Jawline Definition', scanA.overallSymmetry + 2, scanB.overallSymmetry + 5), // Mocking specific deltas
        _buildMetricRow('Eye Area', scanA.eyeSize, scanB.eyeSize),
      ],
    );
  }

  Widget _buildMetricRow(String label, double valA, double valB) {
    final delta = valB - valA;
    final isPositive = delta >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            Text(
              '${valA.toInt()} → ${valB.toInt()}',
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${delta.toInt()}',
                style: TextStyle(
                  color: isPositive ? AppColors.secondary : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
