import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_stats_provider.dart';
import '../monetization/premium_paywall_screen.dart';
import '../../core/widgets/app_header_fixed.dart';
import '../../shared/widgets/glass_container.dart';

class FaceScoreScreen extends ConsumerStatefulWidget {
  const FaceScoreScreen({super.key});

  @override
  ConsumerState<FaceScoreScreen> createState() => _FaceScoreScreenState();
}

class _FaceScoreScreenState extends ConsumerState<FaceScoreScreen> with TickerProviderStateMixin {
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
       duration: const Duration(seconds: 10),
       vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(userStatsProvider);
    final score = stats.lastFaceScore;

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      appBar: const AppHeader(
        title: 'Analysis Results',
        showBackButton: false,
      ),
      body: Stack(
        children: [
          // 1. Background Nebula Blobs
          _buildBackgroundBlobs(),

          // 2. Main Content
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32).copyWith(bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: [
              // Hero Gauge Section
              _buildHeroGauge(context, score),
              const SizedBox(height: 32),
              
              _buildStatusBadge(),
              const SizedBox(height: 16),
              
              Center(
                child: Text(
                  '+15 COINS EARNED!',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.coinGold, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 2,
                    shadows: [Shadow(color: AppColors.coinGold.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Metrics Section
              Text(
                'DETAILED METRICS',
                style: AppTypography.labelSmall.copyWith(color: Colors.white54, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              _buildMetricCard(
                context, 
                icon: Icons.face_retouching_natural, 
                title: 'Skin Score', 
                value: '${score + 5 > 100 ? 100 : score + 5}', 
                subtitle: 'Significant texture improvement', 
                color: AppColors.primary
              ),
              const SizedBox(height: 16),
              _buildMetricCard(
                context, 
                icon: Icons.architecture, 
                title: 'Jawline Definition', 
                value: '${score - 6}', 
                subtitle: 'Excellent bone structure', 
                color: AppColors.secondary
              ),
              const SizedBox(height: 16),
              _buildMetricCard(
                context, 
                icon: Icons.auto_awesome, 
                title: 'Facial Symmetry', 
                value: '${score + 2}', 
                subtitle: 'Highly balanced features', 
                color: AppColors.tertiary
              ),
              const SizedBox(height: 40),

              // Upgrade Section
              _buildUpgradeCard(context),
              const SizedBox(height: 16),

              // Navigation Actions
              _buildActionButtons(context),
              const SizedBox(height: 32),

              // Achievement Badge
              _buildAchievementBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (50 * _blobController.value),
              right: -50 + (30 * _blobController.value),
              child: _NebulaBlob(
                color: AppColors.primary.withValues(alpha: 0.15),
                size: 300,
              ),
            ),
            Positioned(
              bottom: 100 - (40 * _blobController.value),
              left: -80 + (20 * _blobController.value),
              child: _NebulaBlob(
                color: AppColors.secondary.withValues(alpha: 0.1),
                size: 350,
              ),
            ),
            Positioned(
              top: 300 + (60 * _blobController.value),
              right: 100,
              child: _NebulaBlob(
                color: AppColors.tertiary.withValues(alpha: 0.08),
                size: 250,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroGauge(BuildContext context, int score) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        opacity: 0.03,
        blur: 15,
        child: Column(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                  // Inner Glow
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FACIAL SCORE',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white54,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        borderRadius: 20,
        color: AppColors.secondary,
        opacity: 0.1,
        borderOpacity: 0.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.secondary, blurRadius: 10)],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Growth Potential: High',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String value, 
    required String subtitle, 
    required Color color
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(value, style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPaywallScreen())),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.kineticGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Icon(Icons.rocket_launch, color: Colors.white.withValues(alpha: 0.1), size: 120),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PREMIUM INSIGHTS',
                          style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock Your 30-Day\nTransformation Plan',
                      style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'GET STARTED',
                        style: AppTypography.labelMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: GlassContainer(
            borderRadius: 16,
            color: Colors.white,
            opacity: 0.05,
            borderOpacity: 0.1,
            child: TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/main-navigation'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_rounded, color: Colors.white70),
                  const SizedBox(width: 12),
                  Text(
                    'Return to Dashboard',
                    style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 24,
        opacity: 0.01,
        borderOpacity: 0.05,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: AppColors.tertiary, size: 16),
            const SizedBox(width: 8),
            Text(
              'NEW BADGE: EARLY BLOOMER',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.tertiary, 
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NebulaBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _NebulaBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}
