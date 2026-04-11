import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/app_header_fixed.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Weekly Report',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Visual Evolution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VISUAL EVOLUTION', style: AppTypography.eyebrow.copyWith(color: AppColors.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('Last 7 Days', style: AppTypography.eyebrow.copyWith(color: AppColors.secondary)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 3/4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400&auto=format&fit=crop', fit: BoxFit.cover, color: Colors.grey, colorBlendMode: BlendMode.saturation),
                      ),
                    ),
                    Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)), child: Text('BEFORE', style: AppTypography.eyebrow))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 3/4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400&auto=format&fit=crop'), // Normally a different pic :)
                            fit: BoxFit.cover,
                          )
                        ),
                      ),
                    ),
                    Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), child: Text('TODAY', style: AppTypography.eyebrow.copyWith(color: AppColors.surfaceLowest)))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Trend Score
          Container(
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1))),
             child: Column(
               children: [
                 Text('Face Growth Score', style: AppTypography.labelLarge.copyWith(color: AppColors.onSurfaceVariant)),
                 const SizedBox(height: 8),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.baseline,
                   textBaseline: TextBaseline.alphabetic,
                   children: [
                     ShaderMask(
                        shaderCallback: (bounds) => AppColors.kineticGradient.createShader(bounds),
                        child: Text('71', style: AppTypography.displayLarge.copyWith(color: AppColors.onSurface)),
                     ),
                     const SizedBox(width: 8),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
                       child: Row(
                         children: [
                           const Icon(Icons.trending_up, color: AppColors.onSecondary, size: 12),
                           const SizedBox(width: 2),
                           Text('+4', style: AppTypography.eyebrow.copyWith(color: AppColors.onSecondary)),
                         ],
                       ),
                     )
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text.rich(TextSpan(
                   style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                   children: [
                     const TextSpan(text: 'Up from '),
                     TextSpan(text: '67 ', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                     const TextSpan(text: 'last Monday'),
                   ]
                 )),
               ],
             ),
          ),
          const SizedBox(height: 32),
          
          // Metric Breakdown Bars
          Text('Metric Breakdown', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          MetricCard(
            value: '78%',
            label: 'Jawline Definition',
            valueColor: AppColors.primary,
            icon: Icon(Icons.architecture, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          MetricCard(
            value: '64%',
            label: 'Skin Clarity',
            valueColor: AppColors.secondary,
            icon: Icon(Icons.face, color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          MetricCard(
            value: '89%',
            label: 'Facial Symmetry',
            valueColor: AppColors.tertiary,
            icon: Icon(Icons.balance, color: AppColors.tertiary),
          ),
          const SizedBox(height: 32),
          
          // AI Coach Insights
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.psychology, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GrowUp Coach', style: AppTypography.titleMedium),
                        Text('AI INTELLIGENCE', style: AppTypography.eyebrow.copyWith(color: AppColors.primary)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                _buildTipCard('Better hydration patterns detected in skin texture analysis.'),
                _buildTipCard('Masseter muscle activation suggests effective routine consistency.'),
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildTipCard(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant))),
        ],
      ),
    );
  }
}
