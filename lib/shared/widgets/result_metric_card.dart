import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Beautiful result metric card with animated progress bar
class ResultMetricCard extends StatefulWidget {
  final String label;
  final int score;
  final String? description;
  final Color? customColor;
  final Duration animationDuration;

  const ResultMetricCard({
    super.key,
    required this.label,
    required this.score,
    this.description,
    this.customColor,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<ResultMetricCard> createState() => _ResultMetricCardState();
}

class _ResultMetricCardState extends State<ResultMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _progressAnimation = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForScore(int score) {
    if (score >= 85) return const Color(0xFF00D084); // Vibrant Green
    if (score >= 75) return const Color(0xFF06B6D4); // Cyan/Turquoise
    if (score >= 65) return const Color(0xFFD4AF37); // Gold
    if (score >= 50) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFFF6B6B); // Red
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 75) return 'Great';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = widget.customColor ?? _getColorForScore(widget.score);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Solid black
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Title and Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 13,
                  ),
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            // Middle: Score Display
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  (_progressAnimation.value * 100).toStringAsFixed(0),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -1,
                  ),
                );
              },
            ),
            // Bottom: Progress Bar and Label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: _progressAnimation.value,
                        backgroundColor: AppColors.surfaceHighest.withValues(alpha: 0.6),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _getScoreLabel(widget.score),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of metric cards
class ResultMetricsGrid extends StatelessWidget {
  final Map<String, int> metricsMap;
  final Map<String, String>? descriptions;
  final Map<String, Color>? customColors;

  const ResultMetricsGrid({
    super.key,
    required this.metricsMap,
    this.descriptions,
    this.customColors,
  });

  @override
  Widget build(BuildContext context) {
    final entries = metricsMap.entries.toList();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.15,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: entries.map((entry) {
        return ResultMetricCard(
          label: entry.key,
          score: entry.value,
          description: descriptions?[entry.key],
          customColor: customColors?[entry.key],
        );
      }).toList(),
    );
  }
}
