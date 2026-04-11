import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24).copyWith(bottom: 200, top: 20),
            children: [
              // ===== PAGE TITLE =====
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'AI Assistant',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Center(
                child: Text('TODAY • 10:42 AM', style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
              const SizedBox(height: 24),
              _buildAiBubble(context, 'Analyzing your morning 3D facial scan...'),
              const SizedBox(height: 24),
              _buildUserBubble(context, 'How is my skin looking today compared to yesterday?', '10:43 AM'),
              const SizedBox(height: 24),
              _buildAiAdvancedBubble(context),
              const SizedBox(height: 12),
              _buildActionChips(context),
            ],
          ),
          
          // Fixed Bottom Input Area
          Positioned(
            bottom: 96, // Sits perfectly above the global floating NavBar
            left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Message GrowUp AI...',
                        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: AppColors.surfaceLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.mic, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.kineticGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.kineticGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10)],
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(28), bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.onSurface)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserBubble(BuildContext context, String text, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.kineticGradient,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24), topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10)],
                ),
                child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('READ $time', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildAiAdvancedBubble(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(gradient: AppColors.kineticGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10)]),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(28), bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GROWTH COACH', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 12),
                const Text('Based on your recent scan, your skin texture is improving! I noticed a 12% reduction in redness around the cheek area.', style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                const Text('Would you like a custom routine for today?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 16),
                
                // Recommendation Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.spa, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hydration Boost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            Text('Recommended based on texture', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(24)),
                        child: const Text('Apply', style: TextStyle(color: AppColors.onSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChips(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surfaceLow, border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(24)),
          child: const Text('Yes, show routine', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surfaceLow, border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(24)),
          child: const Text('What changed?', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
