import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class FaceShapeAnalysisToolScreen extends StatefulWidget {
  const FaceShapeAnalysisToolScreen({super.key});

  @override
  State<FaceShapeAnalysisToolScreen> createState() => _FaceShapeAnalysisToolScreenState();
}

class _FaceShapeAnalysisToolScreenState extends State<FaceShapeAnalysisToolScreen> {
  bool isScanning = false;
  String? identifiedShape;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Face Shape Analysis',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Scanner Preview
          _buildScannerPreview(),
          const SizedBox(height: 32),

          // Result Section
          if (identifiedShape != null)
            _buildResultCard()
          else
            _buildInstructions(),

          const SizedBox(height: 32),

          // Recommendations
          if (identifiedShape != null) ...[
            const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 16),
            _buildRecommendationTile('Hair Styles', 'Side-swept bangs or long layers work best.'),
            _buildRecommendationTile('Glasses', 'Wayfarer or rectangular frames contrast well.'),
            _buildRecommendationTile('Accessories', 'Long earrings to elongate the appearance.'),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: isScanning ? null : _startScan,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isScanning ? null : AppColors.kineticGradient,
              color: isScanning ? AppColors.surfaceHigh : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isScanning ? [] : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: Text(
              isScanning ? 'ANALYZING...' : 'START FACE SCAN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isScanning ? AppColors.onSurfaceVariant : Colors.black, letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerPreview() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isScanning ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.1), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Center(child: Icon(Icons.face_retouching_natural_rounded, color: AppColors.primary, size: 120)),
          if (isScanning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Positioned(
                  top: 400 * value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 10, spreadRadius: 2)],
                    ),
                  ),
                );
              },
            ),
          // HUD Overlays
          Positioned(
            top: 20, left: 20,
            child: _buildHUDElement('PRECISION: 99.4%', Icons.biotech_rounded),
          ),
          Positioned(
            bottom: 20, right: 20,
            child: _buildHUDElement('GRID: ACTIVE', Icons.grid_4x4_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDElement(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 10),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.surfaceHigh, AppColors.surfaceLow]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('IDENTIFIED SHAPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(identifiedShape!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Balanced & Harmonious', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Width', '88%'),
              _buildMetric('Length', '92%'),
              _buildMetric('Jaw', 'Classic'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildInstructions() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        SizedBox(height: 16),
        Text('1. Align your face within the frame.', style: TextStyle(color: AppColors.onSurfaceVariant, height: 2)),
        Text('2. Ensure your forehead is visible.', style: TextStyle(color: AppColors.onSurfaceVariant, height: 2)),
        Text('3. Maintain a neutral expression.', style: TextStyle(color: AppColors.onSurfaceVariant, height: 2)),
      ],
    );
  }

  Widget _buildRecommendationTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startScan() {
    setState(() => isScanning = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isScanning = false;
          identifiedShape = 'OVAL';
        });
      }
    });
  }
}
