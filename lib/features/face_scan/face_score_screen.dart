import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_stats_provider.dart';
import '../monetization/premium_paywall_screen.dart';
import '../../core/widgets/app_header_fixed.dart';

class FaceScoreScreen extends ConsumerWidget {
  const FaceScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final score = stats.lastFaceScore;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Analysis',
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero Gauge
          Center(
            child: SizedBox(
              width: 256,
              height: 256,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 14,
                    backgroundColor: AppColors.surfaceHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GLOBAL SCORE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Growth Potential: High', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '+15 COINS EARNED!',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 48),

          // Metrics
          _buildMetricCard(context, icon: Icons.face, title: 'Skin Score: ${score + 5 > 100 ? 100 : score + 5}', subtitle: 'Texture improvement detected', color: AppColors.primary),
          const SizedBox(height: 24),
          _buildMetricCard(context, icon: Icons.architecture, title: 'Jawline: ${score - 6}', subtitle: 'Structure: Good', color: AppColors.secondary),
          const SizedBox(height: 24),
          _buildMetricCard(context, icon: Icons.style, title: 'Hair: ${score + 1}', subtitle: 'Health: Medium', color: AppColors.tertiary),
          const SizedBox(height: 48),

          // Sticky Bottom Actions
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.kineticGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.rocket_launch, color: AppColors.onPrimary),
                    SizedBox(width: 12),
                    Text('Unlock Detailed 30-Day Plan', style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/main-navigation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceHighest, // Depth 1
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.dashboard, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Continue to Dashboard', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.stars, color: AppColors.tertiary, size: 16),
                  SizedBox(width: 8),
                  Text('NEW BADGE AVAILABLE: EARLY BLOOMER', style: TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
              ],
            ),
          ),
          if (color == AppColors.primary)
             const Icon(Icons.show_chart, color: AppColors.primary)
          else if (color == AppColors.secondary)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('ABOVE AVERAGE', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: 64, height: 4,
                  decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(4)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.61,
                    child: Container(decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(4))),
                  ),
                ),
              ],
            )
          else 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('TARGET +15%', style: TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }
}
