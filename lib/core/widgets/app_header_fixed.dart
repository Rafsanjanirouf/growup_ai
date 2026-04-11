import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_stats_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80); // Increased height for better spacing

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          border: Border(
            bottom: BorderSide(
              color: AppColors.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: preferredSize.height,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Left: Back button or Logo
                if (showBackButton)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),

                // Title
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(width: 8),

                // Right: Stats (Streak, Level, Coin, XP)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Streak
                    _StatItem(
                      icon: '🔥',
                      value: '${userStats.streak}',
                      label: 'Streak',
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),

                    // Level
                    _StatItem(
                      icon: '⭐',
                      value: '${userStats.level}',
                      label: 'Lvl',
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),

                    // Coins
                    _StatItem(
                      icon: '💰',
                      value: '${userStats.coins}',
                      label: 'Coin',
                      onTap: () => Navigator.pushNamed(context, '/coin-shop'),
                      isClickable: true,
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
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  final bool isClickable;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: isClickable ? AppColors.primary : AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
