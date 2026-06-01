import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';

/// Beautiful social share buttons for WhatsApp, Instagram, and more
class SocialShareButtons extends StatefulWidget {
  final String scoreText;
  final String shareMessage;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onInstagram;
  final VoidCallback? onMoreShare;

  const SocialShareButtons({
    super.key,
    required this.scoreText,
    required this.shareMessage,
    this.onWhatsApp,
    this.onInstagram,
    this.onMoreShare,
  });

  @override
  State<SocialShareButtons> createState() => _SocialShareButtonsState();
}

class _SocialShareButtonsState extends State<SocialShareButtons>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimations = List.generate(
      3,
      (index) => Tween<Offset>(
        begin: Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _shareViaWhatsApp() {
    widget.onWhatsApp?.call();
    Share.share(
      widget.shareMessage,
      subject: 'My GrowUp AI Face Analysis Result',
    );
  }

  void _shareViaInstagram() {
    widget.onInstagram?.call();
    Share.share(
      widget.shareMessage,
      subject: 'My GrowUp AI Face Analysis Result',
    );
  }

  void _shareMore() {
    widget.onMoreShare?.call();
    Share.share(
      widget.shareMessage,
      subject: 'My GrowUp AI Face Analysis Result',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Share Your Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _slideAnimations[0],
                child: _ShareButton(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  backgroundColor: const Color(0xFF25D366),
                  onTap: _shareViaWhatsApp,
                ),
              ),
              const SizedBox(width: 14),
              SlideTransition(
                position: _slideAnimations[1],
                child: _ShareButton(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  backgroundColor: const Color(0xFFE1306C),
                  onTap: _shareViaInstagram,
                ),
              ),
              const SizedBox(width: 14),
              SlideTransition(
                position: _slideAnimations[2],
                child: _ShareButton(
                  icon: Icons.share,
                  label: 'More',
                  backgroundColor: AppColors.primary,
                  onTap: _shareMore,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _tapController.forward();
  }

  void _onTapUp() {
    _tapController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
