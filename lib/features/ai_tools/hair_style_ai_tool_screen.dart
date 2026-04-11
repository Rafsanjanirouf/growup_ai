import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class HairStyleAIToolScreen extends StatefulWidget {
  const HairStyleAIToolScreen({super.key});

  @override
  State<HairStyleAIToolScreen> createState() => _HairStyleAIToolScreenState();
}

class _HairStyleAIToolScreenState extends State<HairStyleAIToolScreen> {
  String selectedStyle = 'Modern Fade';
  bool showBefore = true;

  final List<HairStyle> styles = [
    HairStyle(name: 'Classic Taper', cost: 20, description: 'Timeless look'),
    HairStyle(name: 'Modern Fade', cost: 30, description: 'Contemporary style'),
    HairStyle(name: 'Textured Crop', cost: 35, description: 'Trendy textured'),
    HairStyle(name: 'Slicked Back', cost: 25, description: 'Sophisticated'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Hair Style AI',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // AR Preview
          _buildARPreview(),
          const SizedBox(height: 32),

          // Style Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SELECT STYLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
              Text('${styles.length} Options', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),

          // Style Carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                styles.length,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index == styles.length - 1 ? 0 : 12),
                  child: _buildStyleCard(styles[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // AI Analysis
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hair Analysis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hair Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          const Text('Wavy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Face Shape Match', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          const Text('Excellent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pro Tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pro Tip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'Your hair texture works best with textured styles. Combine with proper grooming routine for maximum impact.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Applying $selectedStyle...')),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.kineticGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.scrimLight, size: 20),
                const SizedBox(width: 8),
                const Text('Apply Style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.scrimLight, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARPreview() {
    return Container(
      height: 400,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(color: AppColors.surfaceHigh, child: const Icon(Icons.face, color: AppColors.primary, size: 120)),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(color: AppColors.modalOverlay, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.scrimLight.withValues(alpha: 0.15))),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('BEFORE', true),
                    _buildToggleButton('AFTER', false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => showBefore = isActive),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: isActive ? AppColors.scrimLight : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? AppColors.secondary : AppColors.scrimLight.withValues(alpha: 0.6), letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildStyleCard(HairStyle style) {
    bool isSelected = selectedStyle == style.name;
    return GestureDetector(
      onTap: () => setState(() => selectedStyle = style.name),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceHigh,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cut, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 24),
            const SizedBox(height: 8),
            Text(style.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurface), textAlign: TextAlign.center, maxLines: 2),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on, color: AppColors.tertiary, size: 11), const SizedBox(width: 2), Text('${style.cost}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.tertiary))]),
          ],
        ),
      ),
    );
  }
}

class HairStyle {
  final String name;
  final int cost;
  final String description;
  HairStyle({required this.name, required this.cost, required this.description});
}
