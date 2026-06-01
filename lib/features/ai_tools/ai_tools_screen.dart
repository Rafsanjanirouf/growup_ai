import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';
import 'hair_style_ai_tool_screen.dart';
import 'ai_try_on_tool_screen.dart';
import 'face_shape_analysis_tool_screen.dart';
import 'best_color_analysis_tool_screen.dart';
import 'beard_style_ai_tool_screen.dart';
import 'celebrity_face_match_tool_screen.dart';
import 'skin_analyzer_tool_screen.dart';
import 'outfit_style_ai_tool_screen.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'AI HUB',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero Title
          Stack(
            children: [
              Positioned(
                top: -20, left: -20,
                child: Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 80)],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Tools', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 16),
                  const Text(
                    'Elevate your presence with professional-grade generative insights. Precision growth at your fingertips.',
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Tools Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75, // Tall cards
            children: [
              _buildToolCard(context, 'Hairstyle AI', 'Try 50+ trending cuts.', Icons.content_cut, price: 25, screen: const HairStyleAIToolScreen()),
              _buildToolCard(context, 'AI Try On', 'Virtual generate outfit.', Icons.checkroom, price: 30, screen: const AiTryOnToolScreen()),
              _buildToolCard(context, 'Face Shape', 'Analyze facial geometry.', Icons.face, isFree: true, screen: const FaceShapeAnalysisToolScreen()),
              _buildToolCard(context, 'Dress Color', 'Best palette for you.', Icons.palette, price: 20, screen: const BestColorAnalysisToolScreen()),
              _buildToolCard(context, 'Beard AI', 'Visualize perfect facial hair.', Icons.face_retouching_natural, isFree: true, freeCount: 'Free 2/day', screen: const BeardStyleAIToolScreen()),
              _buildToolCard(context, 'Celeb Match', 'Find your A-list lookalike.', Icons.stars, price: 35, screen: const CelebrityFaceMatchToolScreen()),
              _buildToolCard(context, 'Skin Analyzer', 'Deep scan metrics.', Icons.biotech, price: 40, screen: const SkinAnalyzerToolScreen()),
              _buildToolCard(context, 'Outfit AI', 'AI-curated wardrobe.', Icons.checkroom, price: 20, screen: const OutfitStyleAIToolScreen()),
            ],
          ),

          const SizedBox(height: 48),

          // Featured Section
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(32)),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(30)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEW ALPHA FEATURE', style: TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  const Text('3D Dynamic Motion Avatar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 16),
                  const Text('Convert a selfie into a fully riggable 3D avatar.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: const Text('UNLOCK EARLY ACCESS', style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, String subtitle, IconData icon, {bool isFree = false, String freeCount = 'Free', int? price, required Widget screen}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.surfaceHighest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1))),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(child: Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(freeCount.toUpperCase(), style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.tertiary, size: 12),
                      const SizedBox(width: 4),
                      Text('$price coins'.toUpperCase(), style: const TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: AppColors.onSurface, size: 16),
              )
            ],
          )
        ],
      ),
    ),
  );
}
}
