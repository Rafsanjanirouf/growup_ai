import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskTitle;
  final String taskDescription;
  final int dayNumber;
  final int programId;

  const TaskDetailScreen({
    super.key,
    required this.taskTitle,
    required this.taskDescription,
    required this.dayNumber,
    required this.programId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Day ${widget.dayNumber} Task',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // Priority Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'HIGH PRIORITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Task Title
          Text(
            widget.taskTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          // Difficulty & Time Estimate
          Row(
            children: [
              _buildInfoPill('Difficulty', 'Medium', AppColors.secondary),
              const SizedBox(width: 12),
              _buildInfoPill('Duration', '15 mins', AppColors.primary),
            ],
          ),
          const SizedBox(height: 32),

          // Task Description Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TASK DESCRIPTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.taskDescription,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.onSurface,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Focus Points
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KEY FOCUS POINTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFocusPoint('Consistency is key. Complete this task every day to build habits.'),
                const SizedBox(height: 12),
                _buildFocusPoint('Take before & after photos to track your visual progress.'),
                const SizedBox(height: 12),
                _buildFocusPoint('Share your progress to unlock bonus coins and achievements.'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Progress Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      isCompleted ? 'Completed ✓' : 'In Progress',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: isCompleted ? 1.0 : 0.6,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceLowest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Rewards Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.tertiary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rewards for Completion',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('50 ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.tertiary)),
                          const Text('🪙 + 1 ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompleted)
              GestureDetector(
                onTap: () {
                  setState(() => isCompleted = true);
                  // Show completion celebration or navigate to next task
                  final messenger = ScaffoldMessenger.of(context);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Task Completed! +50 coins earned!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
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
                      'Mark as Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.scrimLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: const Center(
                  child: Text(
                    '✓ Task Completed Today',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (!isCompleted)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Center(
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: AppColors.kineticGradient,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '✓',
              style: TextStyle(color: AppColors.scrimLight, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
