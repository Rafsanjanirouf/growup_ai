import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class BestColorAnalysisToolScreen extends StatefulWidget {
  const BestColorAnalysisToolScreen({super.key});

  @override
  State<BestColorAnalysisToolScreen> createState() => _BestColorAnalysisToolScreenState();
}

class _BestColorAnalysisToolScreenState extends State<BestColorAnalysisToolScreen> {
  String? selectedSeason;
  
  final Map<String, List<Color>> seasonPalettes = {
    'SPRING': [const Color(0xFFFDBB2D), const Color(0xFF22C1C3), const Color(0xFFF06292), const Color(0xFF81C784)],
    'SUMMER': [const Color(0xFF90CAF9), const Color(0xFFCE93D8), const Color(0xFF80CBC4), const Color(0xFFFFF59D)],
    'AUTUMN': [const Color(0xFFE64A19), const Color(0xFF5D4037), const Color(0xFFFBC02D), const Color(0xFF388E3C)],
    'WINTER': [const Color(0xFF0D47A1), const Color(0xFFC62828), const Color(0xFF4A148C), const Color(0xFF004D40)],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Best Color Analysis',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero Preview
          _buildColorPreview(),
          const SizedBox(height: 32),

          // Season Selection
          const Text('Your Seasonal Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: seasonPalettes.keys.map((season) => _buildSeasonCard(season)).toList(),
          ),
          const SizedBox(height: 32),

          // Palette Analysis
          if (selectedSeason != null) ...[
            Text('YOUR $selectedSeason PALETTE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1))),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: seasonPalettes[selectedSeason]!.map((color) => Expanded(child: Container(color: color))).toList(),
              ),
            ),
            const SizedBox(height: 32),
            
            // Clothing Recommendations
            const Text('Clothing Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildClothingTip('Tops', 'Focus on solid saturated colors to highlight your jawline.'),
            _buildClothingTip('Suits', 'Midnight blue or deep charcoal maintains the best contrast.'),
            _buildClothingTip('Casual', 'White or light grey bases work perfectly for layering.'),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating full color catalog...'))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: AppColors.kineticGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: const Text('GET FULL CATALOG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Center(child: Icon(Icons.person_outline_rounded, color: Colors.white24, size: 100)),
          if (selectedSeason != null)
            ...List.generate(4, (index) => Positioned(
              left: index * 40.0 + 20,
              top: index * 40.0 + 20,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: seasonPalettes[selectedSeason]![index].withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
              ),
            )),
          Positioned(
            bottom: 24, left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SKIN UNDERTONE', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(selectedSeason == 'WINTER' || selectedSeason == 'SUMMER' ? 'COOL (PINK)' : 'WARM (YELLOW)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCard(String season) {
    bool isSelected = selectedSeason == season;
    return GestureDetector(
      onTap: () => setState(() => selectedSeason = season),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.1), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(season, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }

  Widget _buildClothingTip(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
