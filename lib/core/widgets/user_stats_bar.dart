import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/user_stats_provider.dart';

/// A premium, dark-themed top bar showing user statistics.
/// Matches the design from the reference image.
class UserStatsBar extends ConsumerWidget {
  const UserStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow, // Dark gray/black background
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFFF9800), // Fire Orange
              value: '${userStats.streak}',
              label: 'Streak',
            ),
            _StatItem(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF4CAF50), // Success Green
              value: '${userStats.freeScansLeft}',
              label: 'Scans Left',
            ),
            _StatItem(
              icon: Icons.monetization_on,
              iconColor: AppColors.coinGold,
              value: '${userStats.coins}',
              label: 'Coins',
            ),
            _StatItem(
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.primary,
              value: '${userStats.level}',
              label: 'Level',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
