import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'bottom_action_button.dart';

class PremiumDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback? onConfirm;

  const PremiumDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.buttonLabel = 'GOT IT',
    this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    String buttonLabel = 'GOT IT',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => PremiumDialog(
        title: title,
        message: message,
        icon: icon,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 24),
                
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.kineticGradient.createShader(bounds),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Button
                SingleChildScrollView(
                  child: BottomActionButton(
                    label: buttonLabel,
                    isPulsing: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
