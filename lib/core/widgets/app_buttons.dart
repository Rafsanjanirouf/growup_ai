import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Premium primary CTA button with gradient background
class PrimaryCTAButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final EdgeInsets padding;

  const PrimaryCTAButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.kineticGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: AppColors.onPrimary, size: 20),
                  const SizedBox(width: 10),
                ],
                if (!isLoading)
                  Text(
                    label,
                    style: AppTypography.ctaButton,
                    textAlign: TextAlign.center,
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button with border
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final EdgeInsets padding;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                ],
                if (!isLoading)
                  Text(
                    label,
                    style: AppTypography.secondaryButton,
                    textAlign: TextAlign.center,
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact icon button
class CompactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final double iconSize;
  final String? tooltip;

  const CompactIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primary,
    this.size = 48,
    this.iconSize = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline button with icon
class OutlineIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final Color color;
  final double size;
  final double iconSize;

  const OutlineIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.color = AppColors.primary,
    this.size = 48,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: label != null ? 16 : 0),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: iconSize,
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(label!, style: AppTypography.titleSmall.copyWith(color: color)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Elevated action button
class ElevatedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final double height;

  const ElevatedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.onPrimary,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
