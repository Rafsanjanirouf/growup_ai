import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class OutfitStyleAIToolScreen extends StatefulWidget {
  const OutfitStyleAIToolScreen({super.key});

  @override
  State<OutfitStyleAIToolScreen> createState() => _OutfitStyleAIToolScreenState();
}

class _OutfitStyleAIToolScreenState extends State<OutfitStyleAIToolScreen> {
  int selectedOutfitIndex = 0;
  
  final List<OutfitRecommendation> outfits = [
    OutfitRecommendation(name: 'Casual Chic', colors: ['Navy', 'White', 'Tan'], vibe: 'Relaxed', match: '94%'),
    OutfitRecommendation(name: 'Business Formal', colors: ['Black', 'White', 'Grey'], vibe: 'Professional', match: '89%'),
    OutfitRecommendation(name: 'Street Style', colors: ['Olive', 'White', 'Black'], vibe: 'Trendy', match: '91%'),
    OutfitRecommendation(name: 'Date Night', colors: ['Charcoal', 'Burgundy', 'Gold'], vibe: 'Sophisticated', match: '96%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Outfit Style AI',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // Analysis Text
          const Text('Based on your body type, skin tone, and face shape, here are outfit recommendations:', style: TextStyle(fontSize: 14, color: AppColors.onSurface, height: 1.6)),
          const SizedBox(height: 24),

          // Outfit Cards Carousel
          SizedBox(
            height: 320,
            child: PageView.builder(
              onPageChanged: (index) => setState(() => selectedOutfitIndex = index),
              itemCount: outfits.length,
              itemBuilder: (context, index) => _buildOutfitCard(outfits[index]),
            ),
          ),
          const SizedBox(height: 12),

          // Page Indicator
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                outfits.length,
                (index) => Container(
                  width: index == selectedOutfitIndex ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: index == selectedOutfitIndex ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Color Palette
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RECOMMENDED COLORS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: outfits[selectedOutfitIndex].colors.map((color) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))), child: Text(color, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface)))).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Style Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pro Styling Tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                _buildTip('Pair with classic sneakers for casual comfort'),
                const SizedBox(height: 8),
                _buildTip('Add accessories that complement your skin tone'),
                const SizedBox(height: 8),
                _buildTip('Ensure proper fit - tailored pieces elevate any outfit'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving outfit to favorites...'))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: AppColors.scrimLight, size: 20),
                const SizedBox(width: 8),
                const Text('Save Outfit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scrimLight, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitCard(OutfitRecommendation outfit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(outfit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.scrimLight)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.scrimLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)), child: Text(outfit.match, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.scrimLight))),
                ],
              ),
              const SizedBox(height: 12),
              Text('Vibe: ${outfit.vibe}', style: TextStyle(fontSize: 13, color: AppColors.scrimLight.withValues(alpha: 0.9))),
            ],
          ),
          Container(
            height: 140,
            decoration: BoxDecoration(color: AppColors.scrimLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.checkroom, color: AppColors.scrimLight, size: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb, color: AppColors.secondary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.onSurface))),
      ],
    );
  }
}

class OutfitRecommendation {
  final String name;
  final List<String> colors;
  final String vibe;
  final String match;
  OutfitRecommendation({required this.name, required this.colors, required this.vibe, required this.match});
}
