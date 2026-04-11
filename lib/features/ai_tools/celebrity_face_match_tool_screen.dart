import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class CelebrityFaceMatchToolScreen extends StatefulWidget {
  const CelebrityFaceMatchToolScreen({super.key});

  @override
  State<CelebrityFaceMatchToolScreen> createState() => _CelebrityFaceMatchToolScreenState();
}

class _CelebrityFaceMatchToolScreenState extends State<CelebrityFaceMatchToolScreen> {
  int selectedMatchIndex = 0;

  final List<CelebrityMatch> matches = [
    CelebrityMatch(name: 'Chris Hemsworth', matchPercentage: 87, features: ['Strong Jawline', 'Blue Eyes', 'Symmetry']),
    CelebrityMatch(name: 'Idris Elba', matchPercentage: 84, features: ['Facial Structure', 'Cheekbones', 'Overall Look']),
    CelebrityMatch(name: 'Henry Cavill', matchPercentage: 79, features: ['Jawline Shape', 'Eye Position', 'Face Proportion']),
    CelebrityMatch(name: 'Dev Patel', matchPercentage: 92, features: ['Face Shape', 'Feature Placement', 'Symmetry Score']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Celebrity Face Match',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // Heading
          const Text('Your Celebrity Lookalikes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface, height: 1.3)),
          const SizedBox(height: 8),
          Text('Based on facial geometry analysis', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),

          // Match Cards Carousel
          SizedBox(
            height: 380,
            child: PageView.builder(
              onPageChanged: (index) => setState(() => selectedMatchIndex = index),
              itemCount: matches.length,
              itemBuilder: (context, index) => _buildMatchCard(matches[index]),
            ),
          ),
          const SizedBox(height: 12),

          // Page Indicator
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                matches.length,
                (index) => Container(
                  width: index == selectedMatchIndex ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: index == selectedMatchIndex ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Top Matching Features
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATCHING FEATURES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                const SizedBox(height: 12),
                ...matches[selectedMatchIndex].features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 8),
                        Text(feature, style: const TextStyle(fontSize: 12, color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Analysis Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Technical Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                _buildDetailRow('Facial Symmetry', '0.92'),
                const SizedBox(height: 8),
                _buildDetailRow('Jawline Match', '89%'),
                const SizedBox(height: 8),
                _buildDetailRow('Eye Spacing', '87%'),
                const SizedBox(height: 8),
                _buildDetailRow('Overall Proportion', '91%'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing match results...'))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, color: AppColors.scrimLight, size: 20),
                const SizedBox(width: 8),
                const Text('Share Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scrimLight, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(CelebrityMatch match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(color: AppColors.surfaceHigh, child: const Icon(Icons.person, color: AppColors.primary, size: 120)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.surface.withValues(alpha: 0.95), AppColors.surface.withValues(alpha: 0)],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(match.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.kineticGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('${match.matchPercentage}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.scrimLight)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: match.matchPercentage / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceLowest,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      ],
    );
  }
}

class CelebrityMatch {
  final String name;
  final int matchPercentage;
  final List<String> features;
  CelebrityMatch({required this.name, required this.matchPercentage, required this.features});
}
