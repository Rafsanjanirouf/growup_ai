import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Premium highlight card with gradient background
class PremiumHighlightCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final Widget? child;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final EdgeInsets padding;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const PremiumHighlightCard({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.child,
    this.onTap,
    this.gradient,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 20,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.kineticGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ?? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child ??
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.eyebrow,
                  ),
                if (subtitle != null) const SizedBox(height: 8),
                if (title != null)
                  Text(
                    title!,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.scrimLight,
                    ),
                  ),
                if (title != null && description != null) const SizedBox(height: 12),
                if (description != null)
                  Text(
                    description!,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.scrimLight.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

/// Professional info card with icon
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Color? bgColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double borderRadius;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.bgColor,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = bgColor ?? AppColors.primary.withValues(alpha: 0.08);
    final color = iconColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ] else
              Icon(Icons.arrow_forward, color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Statistical metric card
class MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Widget? icon;
  final Color? valueColor;
  final Color? bgColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.valueColor,
    this.bgColor,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: 12),
            ],
            Text(
              value,
              style: AppTypography.displaySmall.copyWith(
                color: valueColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress card with visual indicator
class ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String? progressLabel;
  final Color? progressColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double borderRadius;

  const ProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.progressLabel,
    this.progressColor,
    this.onTap,
    this.trailing,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final color = progressColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.surfaceLow,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (progressLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                progressLabel!,
                style: AppTypography.labelSmall.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feature showcase card with image support
class FeatureCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget imageWidget;
  final VoidCallback? onTap;
  final double imageHeight;
  final double borderRadius;
  final bool showBadge;
  final String? badgeText;

  const FeatureCard({
    super.key,
    this.title,
    this.description,
    required this.imageWidget,
    this.onTap,
    this.imageHeight = 180,
    this.borderRadius = 20,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: imageWidget,
                  ),
                ),
                if (showBadge && badgeText != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeText!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (title != null || description != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title!, style: AppTypography.titleMedium),
                    if (title != null && description != null)
                      const SizedBox(height: 8),
                    if (description != null)
                      Text(
                        description!,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
