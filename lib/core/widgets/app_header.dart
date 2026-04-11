import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/user_stats_provider.dart';

/// Universal header widget for all screens
/// Fixed height: 120px (AppBar 56 + Stats Bar 64)
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    return Column(
      children: [
        // Main AppBar
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Back button or Leading widget
                if (showBackButton && Navigator.canPop(context))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                  )
                else if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: leading,
                  ),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Actions
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
        // Stats bar
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighest,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Streak
                _StatsBadge(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${userStats.streak}',
                  color: AppColors.warning,
                ),
                // Free Scans Left
                _StatsBadge(
                  icon: Icons.check_circle,
                  label: 'Scans Left',
                  value: '${userStats.freeScansLeft}',
                  color: AppColors.success,
                ),
                // Coins
                _StatsBadge(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: '${userStats.coins}',
                  color: AppColors.coinGold,
                ),
                // Level/Score
                _StatsBadge(
                  icon: Icons.trending_up,
                  label: 'Level',
                  value: '${(userStats.lastFaceScore / 20).ceil()}',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

/// Individual stats badge component
class _StatsBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified header for onboarding/auth screens (no stats)
class SimpleHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const SimpleHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showBackButton && Navigator.canPop(context))
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primary,
                ),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              ),
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
