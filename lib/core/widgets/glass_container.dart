import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final double glowRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.06,
    this.borderRadius = 24.0,
    this.border,
    this.padding = const EdgeInsets.all(20.0),
    this.glowColor,
    this.glowRadius = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glowColor != null
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: glowColor!.withAlpha((0.15 * 255).toInt()),
                  blurRadius: glowRadius,
                  spreadRadius: 2,
                )
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((opacity * 255).toInt()),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
