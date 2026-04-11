import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bottom_action_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/voice_guide_provider.dart';

class TrustReviewsScreen extends ConsumerWidget {
  const TrustReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger AI Voice Guide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceGuideProvider.notifier).speak(
        "See how our community of fifty thousand glowers has transformed. Your results are just one step away."
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image (Static version from onboarding)
          Positioned.fill(
            child: Image.asset(
              'assets/image/avater_image.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
          
          // Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header
                Text(
                  'REAL REVIEWS',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Rating Hero
                _buildRatingHero(),
                
                const SizedBox(height: 40),
                
                // Reviews List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildReviewCard(
                        name: 'Marcus V.',
                        role: 'Lookmaxing Pro',
                        rating: 5.0,
                        review: 'Finally an app that tracks real progress. The growth tree is so motivating and keeps me consistent every single day!',
                      ),
                      _buildReviewCard(
                        name: 'Sarah L.',
                        role: 'Premium Member',
                        rating: 5.0,
                        review: 'The AI analysis is surprisingly accurate. Best tool I have found for tracking my jawline and skin improvements.',
                      ),
                      _buildReviewCard(
                        name: 'David K.',
                        role: 'GlowUp Enthusiast',
                        rating: 4.5,
                        review: 'GlowUp AI helped me fix my skincare routine in just 2 weeks. The live AI assistant is like having a private mentor.',
                      ),
                      _buildReviewCard(
                        name: 'Ethan J.',
                        role: 'Fitness Coach',
                        rating: 5.0,
                        review: 'Professional-grade results. I recommend this to all my clients who want to track their total transformation.',
                      ),
                      const SizedBox(height: 120), // Space for button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pulsing Start Button
          BottomActionButton(
            label: 'START MY JOURNEY',
            icon: Icons.rocket_launch,
            isPulsing: true, // New premium animation
            onTap: () => Navigator.of(context).pushReplacementNamed('/auth'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Icon(
              Icons.star_rounded,
              color: AppColors.primary,
              size: 32,
            )),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '4.9/5 ',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: 'Rating',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TRUSTED BY 50,000+ GLOWERS',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String role,
    required double rating,
    required String review,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(name[0], style: const TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                  Text(role, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(rating.toString(), style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
