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
  String selectedFaceShape = 'OVAL';
  bool showBefore = true;
  bool isAnalyzing = false;

  final List<String> faceShapes = ['OVAL', 'ROUND', 'SQUARE', 'HEART', 'DIAMOND'];

  final List<HairStyle> styles = [
    HairStyle(
      name: 'Classic Taper',
      cost: 20,
      description: 'Timeless professional look',
      recommendedFaceShapes: ['OVAL', 'SQUARE'],
    ),
    HairStyle(
      name: 'Modern Fade',
      cost: 30,
      description: 'Contemporary textured style',
      recommendedFaceShapes: ['ROUND', 'OVAL'],
    ),
    HairStyle(
      name: 'Textured Crop',
      cost: 35,
      description: 'Trendy short texture',
      recommendedFaceShapes: ['HEART', 'DIAMOND'],
    ),
    HairStyle(
      name: 'Slicked Back',
      cost: 25,
      description: 'Sophisticated clean look',
      recommendedFaceShapes: ['OVAL', 'SQUARE', 'DIAMOND'],
    ),
    HairStyle(
      name: 'Side Part',
      cost: 25,
      description: 'Versatile gentleman style',
      recommendedFaceShapes: ['SQUARE', 'ROUND', 'OVAL'],
    ),
    HairStyle(
      name: 'Buzz Cut',
      cost: 15,
      description: 'Minimalist low maintenance',
      recommendedFaceShapes: ['OVAL', 'DIAMOND'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    bool isBestMatch = styles.firstWhere((s) => s.name == selectedStyle).recommendedFaceShapes.contains(selectedFaceShape);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Hairstyle AI',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 140),
            physics: const BouncingScrollPhysics(),
            children: [
              // AR Preview
              _buildARPreview(),
              const SizedBox(height: 32),

              // Face Shape Selection
              _buildFaceShapeSelector(),
              const SizedBox(height: 32),

              // Style Selection Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHOOSE HAIRSTYLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${styles.length} Options',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Style List
              _buildStyleList(),
              const SizedBox(height: 32),

              // Smart Analysis
              _buildSmartAnalysisCard(isBestMatch),
              const SizedBox(height: 24),

              // Pro Tip
              _buildProTipCard(),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withValues(alpha: 0),
                    AppColors.surface.withValues(alpha: 0.9),
                    AppColors.surface,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: _buildBottomAction(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARPreview() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
        color: AppColors.surfaceHigh,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main Preview Area
          Center(
            child: Icon(
              Icons.face_retouching_natural_rounded,
              color: AppColors.primary.withValues(alpha: 0.15),
              size: 160,
            ),
          ),
          
          // Subtle Vignet
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
                ),
              ),
            ),
          ),

          // Before/After Toggle
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.modalOverlay,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('BEFORE', showBefore),
                    _buildToggleButton('AFTER', !showBefore),
                  ],
                ),
              ),
            ),
          ),

          // Reset Action
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => setState(() => showBefore = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => showBefore = label == 'BEFORE'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.black : Colors.white60,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceShapeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'YOUR FACE SHAPE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: _simulateAnalysis,
              child: Text(
                isAnalyzing ? 'ANALYZING...' : 'RE-SCAN AI',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: faceShapes.length,
            itemBuilder: (context, index) {
              final shape = faceShapes[index];
              final isSelected = selectedFaceShape == shape;
              return GestureDetector(
                onTap: () => setState(() => selectedFaceShape = shape),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    shape,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.black : AppColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: styles.length,
        itemBuilder: (context, index) {
          final style = styles[index];
          final isSelected = selectedStyle == style.name;
          final isMatch = style.recommendedFaceShapes.contains(selectedFaceShape);

          return GestureDetector(
            onTap: () => setState(() => selectedStyle = style.name),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.content_cut_rounded,
                        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        style.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.token_rounded, color: AppColors.warning, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              '${style.cost}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isMatch)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.black, size: 10),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmartAnalysisCard(bool isBestMatch) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPATIBILITY ANALYSIS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              if (isBestMatch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OPTIMAL MATCH',
                    style: TextStyle(color: AppColors.secondary, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAnalysisRow('Face Geometry', isBestMatch ? 'Compatible' : 'Incompatible', isBestMatch ? AppColors.secondary : AppColors.error),
          const SizedBox(height: 12),
          _buildAnalysisRow('Volume Balance', 'Superior', AppColors.primary),
          const SizedBox(height: 12),
          _buildAnalysisRow('Structural Strength', 'High', Colors.white),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildProTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TECH RECOMMENDATION',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                SizedBox(height: 6),
                Text(
                  'Your face structure suggests higher volume on top. Use a matte wax for texture.',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Visualizing $selectedStyle for $selectedFaceShape...'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: AppColors.kineticGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.black, size: 24),
                SizedBox(width: 16),
                Text(
                  'APPLY HAIRSTYLE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _simulateAnalysis() {
    setState(() => isAnalyzing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
          selectedFaceShape = 'OVAL'; // Simulated result
        });
      }
    });
  }
}

class HairStyle {
  final String name;
  final int cost;
  final String description;
  final List<String> recommendedFaceShapes;

  HairStyle({
    required this.name,
    required this.cost,
    required this.description,
    required this.recommendedFaceShapes,
  });
}
