import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class SkinAnalyzerToolScreen extends StatefulWidget {
  const SkinAnalyzerToolScreen({super.key});

  @override
  State<SkinAnalyzerToolScreen> createState() => _SkinAnalyzerToolScreenState();
}

class _SkinAnalyzerToolScreenState extends State<SkinAnalyzerToolScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Skin Analyzer',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // Scan Image
          Container(
            height: 380,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
            clipBehavior: Clip.antiAlias,
            child: Container(color: AppColors.surfaceHigh, child: const Icon(Icons.face, color: AppColors.primary, size: 100)),
          ),
          const SizedBox(height: 32),

          // Analysis Results
          Text('SKIN HEALTH SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3))),
            child: Column(
              children: [
                const Text('78', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: -1)),
                const SizedBox(height: 8),
                const Text('Very Good', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 16),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: 0.78, minHeight: 8, backgroundColor: AppColors.surfaceLowest, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary))),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Analysis Categories
          _buildAnalysisCategory('Hydration Level', '72%', AppColors.primary),
          const SizedBox(height: 12),
          _buildAnalysisCategory('Elasticity', '81%', AppColors.secondary),
          const SizedBox(height: 12),
          _buildAnalysisCategory('Texture Quality', '68%', AppColors.tertiary),
          const SizedBox(height: 32),

          // Recommendations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personalized Recommendations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                _buildRecommendation('Increase hydration routine 2x weekly'),
                const SizedBox(height: 8),
                _buildRecommendation('Use vitamin C serum for elasticity'),
                const SizedBox(height: 8),
                _buildRecommendation('Apply SPF 30+ daily for texture'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating detailed skin report...'))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.scrimLight, size: 20),
                const SizedBox(width: 8),
                const Text('Generate Full Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scrimLight, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCategory(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: color, width: 3), top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)), right: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)), bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.onSurface))),
      ],
    );
  }
}
