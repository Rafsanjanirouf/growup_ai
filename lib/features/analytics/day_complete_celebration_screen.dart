import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';

class DayCompleteCelebrationScreen extends StatefulWidget {
  final int coinsEarned;
  final int streakDays;
  final String nextTaskTitle;
  final VoidCallback? onClose;

  const DayCompleteCelebrationScreen({
    super.key,
    this.coinsEarned = 150,
    this.streakDays = 5,
    this.nextTaskTitle = 'Tomorrow\'s Task',
    this.onClose,
  });

  @override
  State<DayCompleteCelebrationScreen> createState() => _DayCompleteCelebrationScreenState();
}

class _DayCompleteCelebrationScreenState extends State<DayCompleteCelebrationScreen> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  int animatedCoins = 0;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    animationController.forward();

    // Animate coin counter
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted && animatedCoins < widget.coinsEarned) {
        setState(() => animatedCoins += (widget.coinsEarned / 20).ceil());
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onClose?.call();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: ScaleTransition(
            scale: animationController.drive(Tween<double>(begin: 0.8, end: 1.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Celebration Icon
                ShakeTransition(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppColors.kineticGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star, color: AppColors.onSurface, size: 60),
                  ),
                ),
                const SizedBox(height: 40),

                // Main Text
                const Text(
                  'AMAZING! 🎉',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You\'ve completed today\'s tasks!',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                // Reward Cards Grid
                SizedBox(
                  width: MediaQuery.of(context).size.width - 48,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildRewardCard(
                              '${animatedCoins.clamp(0, widget.coinsEarned)} 🪙',
                              'Coins Earned',
                              AppColors.tertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRewardCard(
                              '${widget.streakDays} 🔥',
                              'Day Streak',
                              AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRewardCard(
                        '+ 5 XP',
                        'Experience Points',
                        AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Achievement Badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.workspace_premium, color: AppColors.tertiary, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Consistent Legend',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Completed 5 days in a row!',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Next Task Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NEXT UP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.nextTaskTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  widget.onClose?.call();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.kineticGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Shake animation widget
class ShakeTransition extends StatefulWidget {
  final Widget child;

  const ShakeTransition({super.key, required this.child});

  @override
  State<ShakeTransition> createState() => _ShakeTransitionState();
}

class _ShakeTransitionState extends State<ShakeTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0.05, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}
