import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/premium_provider.dart';

class PremiumPaywallScreen extends ConsumerStatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  ConsumerState<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends ConsumerState<PremiumPaywallScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/splash_bg.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Video
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
            
          // 2. Glass Scrim
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
          
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPromoBadge(),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 32),
                      _buildFeatures(),
                      const SizedBox(height: 48),
                      _buildPricingSection(),
                      const SizedBox(height: 48),
                      _buildReviewsSection(),
                      const SizedBox(height: 120), // Padding for fixed button
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 4. Fixed Bottom CTA
          _buildFixedBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: Text(
              'RESTORE',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Text(
            'LIMITED TIME OFFER',
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

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UNLIMITED\nASCENSION',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Join 50,000+ top performers using AI to reach their genetic potential.',
          style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      children: [
        _buildFeatureItem(Icons.face_retouching_natural, 'Unlimited Face Scans', 'Daily deep analysis & tracking'),
        _buildFeatureItem(Icons.insights, 'Personalized Growth Blueprint', 'Custom AI-generated progress tasks'),
        _buildFeatureItem(Icons.voice_chat, 'AI Voice Companion', '24/7 vocal coaching and feedback'),
        _buildFeatureItem(Icons.workspace_premium, 'Priority Support', 'Direct access to pro human coaching'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Column(
      children: [
        _buildGlassPricingCard(
          title: 'YEARLY ACCESS',
          price: '₹499',
          period: '/yr',
          description: 'Best for long-term transformation',
          isBestValue: true,
        ),
        const SizedBox(height: 16),
        _buildGlassPricingCard(
          title: 'MONTHLY ACCESS',
          price: '₹99',
          period: '/mo',
          description: 'Flexible commitment',
          isBestValue: false,
        ),
      ],
    );
  }

  Widget _buildGlassPricingCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required bool isBestValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBestValue ? AppColors.primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: AppTypography.labelSmall.copyWith(color: isBestValue ? AppColors.primary : Colors.white54, fontWeight: FontWeight.bold)),
                          if (isBestValue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                              child: Text('SAVE 60%', style: AppTypography.labelSmall.copyWith(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: AppTypography.bodySmall.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(price, style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(period, style: AppTypography.labelSmall.copyWith(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'USER TESTIMONIALS',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildReviewCard('Rahul S.', 'My face score improved from 64 to 78 in just 3 months! The AI tasks are insane.', 4.5),
              _buildReviewCard('Arjun V.', 'Best \$7 I ever spent. The symmetry analysis helped me fix my training posture.', 5.0),
              _buildReviewCard('Karan P.', 'Vocal coaching alone is worth the sub. Finally sounding more confident.', 4.8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String user, String comment, double rating) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, size: 14, color: Colors.white54),
              ),
              const SizedBox(width: 8),
              Text(user, style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Icon(Icons.star, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text(rating.toString(), style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: AppTypography.bodySmall.copyWith(color: Colors.white60, height: 1.4),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFixedBottomCTA() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black,
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(premiumProvider.notifier).setPremium(true);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'START YOUR TRANSFORMATION',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.bolt_rounded, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No commitment. Cancel anytime.',
              style: AppTypography.caption.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
