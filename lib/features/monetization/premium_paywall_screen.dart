import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/app_header_fixed.dart';

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Unlock Performance',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Ambient bg
          Positioned(
            top: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 100)])),
          ),
          
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(16)),
                child: Text('PREMIUM ACCESS', style: AppTypography.eyebrow.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 16),
              Text('UNLIMITED\nACCESS', style: AppTypography.displayLarge),
              const SizedBox(height: 16),
              Text('Ascend to your peak potential with AI-driven hyper-growth tools. No limits, just performance.', style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 48),
              
              // Features Grid
              InfoCard(
                icon: Icons.chat_bubble,
                title: 'Unlimited AI Assistant',
                description: '24/7 access to personalized growth coaching.',
                iconColor: AppColors.secondary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      icon: Icons.auto_fix_high,
                      title: '6 Pro AI Tools',
                      description: 'Full access',
                      iconColor: AppColors.primary,
                      borderRadius: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoCard(
                      icon: Icons.military_tech,
                      title: '50 Daily Coins',
                      description: 'Every day',
                      iconColor: AppColors.tertiary,
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      icon: Icons.event_repeat,
                      title: '30-Day Programs',
                      description: 'Unlimited',
                      iconColor: AppColors.secondary,
                      borderRadius: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoCard(
                      icon: Icons.block,
                      title: 'Ad-free',
                      description: 'Pure experience',
                      iconColor: AppColors.onSurfaceVariant,
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Pricing Cards
              // Simulating the Conic Gradient Aura with a SweepGradient and padding
              Container(
                 padding: const EdgeInsets.all(2), // Border thickness
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(24),
                   gradient: const SweepGradient(
                     colors: [AppColors.primary, AppColors.secondary, AppColors.surface, AppColors.primary],
                     stops: [0.0, 0.3, 0.6, 1.0],
                   )
                 ),
                 child: Container(
                   padding: const EdgeInsets.all(24),
                   decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(22)),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Text('YEARLY PLAN', style: AppTypography.eyebrow.copyWith(color: AppColors.tertiary)),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                               decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                               child: Text('BEST VALUE', style: AppTypography.eyebrow.copyWith(color: AppColors.primary)),
                            )
                         ],
                       ),
                       const SizedBox(height: 8),
                       Text('₹499/year', style: AppTypography.displayMedium),
                       Text('~₹41/mo', style: AppTypography.labelLarge.copyWith(color: AppColors.secondary)),
                     ],
                   ),
                 ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surfaceLow, border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MONTHLY PLAN', style: AppTypography.eyebrow.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text('₹99/month', style: AppTypography.headlineLarge),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              PrimaryCTAButton(
                label: 'START YOUR GLOW UP',
                icon: Icons.star,
                onPressed: () {
                  // Handle premium subscription
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('Subscription automatically renews. Cancel anytime.', style: AppTypography.caption.copyWith(color: AppColors.onSurfaceVariant)),
              )
            ],
          ),
        ],
      ),
    );
  }
}
