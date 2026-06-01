import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class AiTryOnToolScreen extends StatefulWidget {
  const AiTryOnToolScreen({super.key});

  @override
  State<AiTryOnToolScreen> createState() => _AiTryOnToolScreenState();
}

class _AiTryOnToolScreenState extends State<AiTryOnToolScreen> {
  bool isGenerating = false;
  String? itemImagePath;
  String? personImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'AI Try On',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header Info
          const Text(
            'Virtual Dressing Room',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload an item and your own photo to see how it looks on you instantly.',
            style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Upload Section
          Row(
            children: [
              Expanded(
                child: _buildUploadCard(
                  title: 'THE ITEM',
                  subtitle: 'Dress, Shirt, etc.',
                  icon: Icons.checkroom_rounded,
                  path: itemImagePath,
                  onTap: () => _pickImage(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUploadCard(
                  title: 'YOUR PHOTO',
                  subtitle: 'Full body or torso',
                  icon: Icons.person_add_alt_1_rounded,
                  path: personImagePath,
                  onTap: () => _pickImage(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Preview Area
          if (isGenerating)
            _buildGeneratingPlaceholder()
          else
            _buildResultPreview(),

          const SizedBox(height: 32),
          
          // Guidelines
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tips for best results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                _buildGuidelineItem(Icons.light_mode_rounded, 'Use photos with good lighting.'),
                _buildGuidelineItem(Icons.accessibility_new_rounded, 'Stand straight facing the camera.'),
                _buildGuidelineItem(Icons.image_aspect_ratio_rounded, 'Avoid cluttered backgrounds.'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: (itemImagePath != null && personImagePath != null) ? _startGeneration : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: (itemImagePath != null && personImagePath != null) 
                  ? AppColors.kineticGradient 
                  : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: (itemImagePath != null && personImagePath != null)
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              'GENERATE LOOK',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w900, 
                color: (itemImagePath != null && personImagePath != null) ? Colors.black : Colors.white38,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({required String title, required String subtitle, required IconData icon, String? path, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: path != null ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.1),
            width: path != null ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: path != null ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(path != null ? Icons.check_circle_rounded : icon, color: path != null ? AppColors.secondary : AppColors.onSurfaceVariant, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.onSurface, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24),
          Text('AI is stitching your look...', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultPreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 48),
            SizedBox(height: 16),
            Text('Combined Preview', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 4),
            Text('Upload both images to generate', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _pickImage(bool isItem) {
    // Mock image picking
    setState(() {
      if (isItem) {
        itemImagePath = 'mock_item_path';
      } else {
        personImagePath = 'mock_person_path';
      }
    });
  }

  void _startGeneration() {
    setState(() => isGenerating = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Look Generated Successfully!')),
        );
      }
    });
  }
}
