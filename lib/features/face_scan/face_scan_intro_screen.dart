import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bottom_action_button.dart';
import 'analyzing_scan_screen.dart';

class FaceScanIntroScreen extends StatefulWidget {
  const FaceScanIntroScreen({super.key});

  @override
  State<FaceScanIntroScreen> createState() => _FaceScanIntroScreenState();
}

class _FaceScanIntroScreenState extends State<FaceScanIntroScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalyzingScanScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Aesthetic - subtle gradient glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // App Branding
                  Text(
                    'STEP 3/3',
                    style: AppTypography.eyebrow.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FEATURES ANALYSIS',
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  
                  const Spacer(),

                  // Central Illustration/Icon
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          blurRadius: 100,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer rotating ring effect (Static for now or use Lottie if available)
                        const Icon(
                          Icons.face_unlock_rounded,
                          size: 100,
                          color: AppColors.secondary,
                        ),
                        // Scanning line animation placeholder
                        Positioned(
                          top: 80,
                          child: Container(
                            width: 140,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  Text(
                    'Unlock Your True Potential',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use our professional-grade AI to analyze your facial symmetry, golden ratio, and genetic traits.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  // Live Scan Button (Primary)
                  BottomActionButton(
                    label: 'LIVE FACE SCAN',
                    icon: Icons.camera_front_rounded,
                    usePositioned: false,
                    isPulsing: true,
                    onTap: () => Navigator.pushNamed(context, '/face-scan'),
                  ),
                  
                  const SizedBox(height: 16),

                  // Pick from Gallery (Secondary Premium)
                  _buildSecondaryButton(
                    label: 'PICK FROM GALLERY',
                    icon: Icons.photo_library_outlined,
                    isLoading: _isPicking,
                    onTap: _pickImage,
                  ),

                  const SizedBox(height: 24),

                  // Skip Button
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/main-navigation'),
                    child: Text(
                      'SKIP FOR NOW',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
              )
            else ...[
              Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
