import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable bottom action button with premium styling and animations
/// Similar to splash screen button with customizable content and animations
class BottomActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final String? loadingText;
  final double bottomOffset;
  final bool showAnimation;
  final bool isPulsing;
  final AnimationController? scaleController;

  const BottomActionButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.loadingText,
    this.bottomOffset = 110, // Sit above the floating navigation bar
    this.showAnimation = true,
    this.isPulsing = false,
    this.scaleController,
  });

  @override
  State<BottomActionButton> createState() => _BottomActionButtonState();
}

class _BottomActionButtonState extends State<BottomActionButton>
    with TickerProviderStateMixin {
  late AnimationController _internalScaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _tabAnimationController;
  late Animation<Offset> _tabAnimation;
  late AnimationController? _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Use provided controller or create internal one
    _internalScaleController = widget.scaleController ??
        AnimationController(
          duration: const Duration(milliseconds: 500),
          vsync: this,
        );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _internalScaleController, curve: Curves.elasticOut),
    );

    // Tab animation controller for button tap effect
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -8))
        .animate(CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut));

    // Pulse animation logic
    _pulseController = widget.isPulsing
        ? AnimationController(
            duration: const Duration(milliseconds: 1500),
            vsync: this,
          )
        : null;

    _pulseAnimation = _pulseController != null
        ? TweenSequence<double>([
            TweenSequenceItem(
                tween: Tween<double>(begin: 1.0, end: 1.05)
                    .chain(CurveTween(curve: Curves.easeInOut)),
                weight: 50),
            TweenSequenceItem(
                tween: Tween<double>(begin: 1.05, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeInOut)),
                weight: 50),
          ]).animate(_pulseController!)
        : const AlwaysStoppedAnimation(1.0);

    // Start animations
    if (widget.showAnimation && widget.scaleController == null) {
      _internalScaleController.forward();
    }
    _pulseController?.repeat();
  }

  @override
  void dispose() {
    if (widget.scaleController == null) {
      _internalScaleController.dispose();
    }
    _tabAnimationController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _tabAnimationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _tabAnimationController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _tabAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottomOffset,
      left: 24,
      right: 24,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: !widget.isLoading
            ? GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                behavior: HitTestBehavior.opaque,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: SlideTransition(
                    position: _tabAnimation,
                    child: _buildButtonContent(),
                  ),
                ),
              )
            : _buildLoadingContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.label,
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 12),
            Icon(
              widget.icon,
              color: Colors.white,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: const AlwaysStoppedAnimation(
            Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.loadingText ?? 'Loading...',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant.withValues(
              alpha: 0.7,
            ),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
