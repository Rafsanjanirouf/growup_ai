import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CoinPill extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;

  const CoinPill({
    super.key,
    required this.coins,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.tertiary, size: 16),
          const SizedBox(width: 6),
          Text(
            coins.toString(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }
    
    return child;
  }
}
