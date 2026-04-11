import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class BeardStyleAIToolScreen extends StatefulWidget {
  const BeardStyleAIToolScreen({super.key});

  @override
  State<BeardStyleAIToolScreen> createState() => _BeardStyleAIToolScreenState();
}

class _BeardStyleAIToolScreenState extends State<BeardStyleAIToolScreen> {
  String selectedStyle = 'Corporate';
  bool showBefore = true;

  final List<BeardStyle> styles = [
    BeardStyle(
      name: 'Stubbe',
      icon: Icons.face_retouching_natural,
      cost: 0,
      isFree: true,
      description: 'Light stubble',
    ),
    BeardStyle(
      name: 'Corporate',
      icon: Icons.person,
      cost: 25,
      description: 'Professional look',
    ),
    BeardStyle(
      name: 'Goatee',
      icon: Icons.mood,
      cost: 15,
      description: 'Stylish goatee',
    ),
    BeardStyle(
      name: 'Full Beard',
      icon: Icons.face,
      cost: 40,
      description: 'Full coverage',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Beard Style AI',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // AR Preview Section
          _buildARPreviewSection(),
          const SizedBox(height: 32),

          // Style Selection Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECT STYLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${styles.length} Options Found',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Style Carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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

          // Stats Bento
          _buildStatsGrid(),
          const SizedBox(height: 32),

          // Info Cards
          _buildInfoCard(
            'Growth Density Analysis',
            'Your beard growth pattern indicates excellent density in the cheek and jaw areas. Perfect for fuller styles.',
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Pro Tip',
            'Match your face shape with the right beard style to maximize your overall appeal.',
            AppColors.secondary,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Applying $selectedStyle style...')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.kineticGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.scrimLight, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Apply Style',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.scrimLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Face Image
          Container(
            width: double.infinity,
            height: 400,
            color: AppColors.surfaceHigh,
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCC8Q0odCvssiKxIsSW13rEGdtQvzTQxJ1gK0TQhfw6AsEHb0yFWJelFSv0O2J_XmK7VJ0RqfPZA3s2kU7urQL8ucIz_DiOZF64JB17HpV9QMkyxIBGkapag5Sf1JLwrgED72XNqbOw3nac5kqQkj67kSwipdjo0o1AC4YGRp5X6OVpKikON_tYIAejwS69-xfRUVHtgTUVLHeLWFPY6PbkAddfWbWgwU5tDfQSAYINEZuOpKnzZ6B8_NlF0JuqWVY3gQbkH1zCZAs',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceHighest,
                child: const Icon(Icons.person, color: AppColors.primary, size: 80),
              ),
            ),
          ),

          // AR Overlay Elements
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Jawline Detection Box
                Center(
                  child: Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // AR Grid
                Container(
                  width: 140,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: const [
                        SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Before/After Toggle
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.modalOverlay,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.scrimLight.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => showBefore = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: showBefore ? AppColors.scrimLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BEFORE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: showBefore ? AppColors.secondary : AppColors.scrimLight.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => showBefore = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: !showBefore ? AppColors.scrimLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'AFTER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: !showBefore ? AppColors.secondary : AppColors.scrimLight.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Scanning Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
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

  Widget _buildStyleCard(BeardStyle style) {
    bool isSelected = selectedStyle == style.name;

    return GestureDetector(
      onTap: () => setState(() => selectedStyle = style.name),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceHigh,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceHighest,
                border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
              ),
              child: Icon(style.icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              style.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (style.isFree)
              const Text(
                'FREE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: AppColors.tertiary, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '${style.cost}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth Density',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      '82%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '+4%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symmetry Score',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      '0.94',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'High',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class BeardStyle {
  final String name;
  final IconData icon;
  final int cost;
  final bool isFree;
  final String description;

  BeardStyle({
    required this.name,
    required this.icon,
    required this.cost,
    this.isFree = false,
    required this.description,
  });
}
