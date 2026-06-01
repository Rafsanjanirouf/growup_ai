import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';

/// Beautiful animated circular progress bar with gradient and glow effects
class AnimatedCircularProgressBar extends StatefulWidget {
  final double score;
  final double size;
  final int strokeWidth;
  final Duration animationDuration;
  final bool showGradient;
  final bool showGlow;
  final String? imagePath;

  const AnimatedCircularProgressBar({
    super.key,
    required this.score,
    this.size = 220,
    this.strokeWidth = 18,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.showGradient = true,
    this.showGlow = true,
    this.imagePath,
  });

  @override
  State<AnimatedCircularProgressBar> createState() =>
      _AnimatedCircularProgressBarState();
}

class _AnimatedCircularProgressBarState
    extends State<AnimatedCircularProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedCircularProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForScore(double score) {
    if (score >= 85) return const Color(0xFF00D084); // Vibrant Green - Excellent
    if (score >= 75) return const Color(0xFF06B6D4); // Cyan/Turquoise - Great
    if (score >= 65) return const Color(0xFFD4AF37); // Gold - Good
    if (score >= 50) return const Color(0xFFFF9800); // Orange - Fair
    return const Color(0xFFFF6B6B); // Red - Needs Work
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Glow effect (background) - Enhanced
              if (widget.showGlow)
                Center(
                  child: Container(
                    width: widget.size * 0.95,
                    height: widget.size * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Outer glow layer
                        BoxShadow(
                          color: _getColorForScore(widget.score)
                              .withValues(alpha: 0.15 * _glowAnimation.value),
                          blurRadius: 70,
                          spreadRadius: 35,
                        ),
                        // Middle glow layer
                        BoxShadow(
                          color: _getColorForScore(widget.score)
                              .withValues(alpha: 0.20 * _glowAnimation.value),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                        // Inner glow layer
                        BoxShadow(
                          color: _getColorForScore(widget.score)
                              .withValues(alpha: 0.25 * _glowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),

              // Background circle
              CustomPaint(
                painter: _CircleProgressPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth.toDouble(),
                  backgroundColor: AppColors.surfaceHighest,
                  foregroundColor: _getColorForScore(widget.score),
                  showGradient: widget.showGradient,
                ),
              ),

              // Main Stack for content
              if (widget.imagePath != null)
                Center(
                  child: Container(
                    width: widget.size * 0.55,
                    height: widget.size * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getColorForScore(widget.score),
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: FileImage(File(widget.imagePath!)),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getColorForScore(widget.score)
                              .withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Fallback if no image
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Text(
                            (_animation.value * 100).toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -2,
                              color: Color(0xFFD4AF37),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SCORE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 3,
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Score Display at Bottom Center - Overlaid
              Positioned(
                bottom: widget.size * 0.08,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getColorForScore(widget.score),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getColorForScore(widget.score)
                                  .withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (_animation.value * 100).toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool showGradient;

  _CircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.showGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc (progress)
    if (showGradient) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        colors: [
          foregroundColor,
          foregroundColor.withValues(alpha: 0.7),
          foregroundColor,
        ],
        startAngle: -3.14159 / 2,
        endAngle: (3.14159 * 2) - (3.14159 / 2),
      );

      canvas.drawArc(
        rect,
        -3.14159 / 2,
        progress * (3.14159 * 2),
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    } else {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -3.14159 / 2,
        progress * (3.14159 * 2),
        false,
        Paint()
          ..color = foregroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
