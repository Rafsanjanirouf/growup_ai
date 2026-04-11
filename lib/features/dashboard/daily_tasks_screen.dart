import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/task_tracker_provider.dart';

class DailyTasksScreen extends ConsumerStatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  ConsumerState<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends ConsumerState<DailyTasksScreen> {
  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskTrackerProvider);
    
    // Check if loading or state is empty
    if (taskState.isLoading || taskState.days.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentDayTasks = taskState.days[taskState.currentDay] ?? [];
    final completedCount = currentDayTasks.where((t) => t.isCompleted).length;
    final progressPercent = (taskState.overallProgress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 140),
        physics: const BouncingScrollPhysics(),
        children: [
          // ===== PAGE TITLE =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Tree Growth',
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // ===== GROWTH TREE HERO SECTION =====
          _buildTreeHero(taskState.treeFrame, taskState.overallProgress),

          const SizedBox(height: 16),

          // ===== DAYS SELECTOR (HORIZONTAL) =====
          _buildDaysSelector(taskState.currentDay),

          const SizedBox(height: 24),

          // ===== MISSION LIST =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day ${taskState.currentDay} Missions',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completedCount/${currentDayTasks.length}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._buildTasksList(currentDayTasks, taskState.currentDay),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ===== PROGRESS STATS =====
          _buildProgressStats(progressPercent, taskState.overallProgress),
        ],
      ),
    );
  }

  // ===== GROWTH TREE HERO =====
  Widget _buildTreeHero(int frameIndex, double overallProgress) {
    // Format frame index with leading zeros if necessary
    final frameString = frameIndex.toString().padLeft(3, '0');
    
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLow,
            AppColors.surfaceLowest,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Growth Image
          Image.asset(
            'assets/images/tree/ezgif-frame-$frameString.png',
            height: 280,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.park_rounded, size: 80, color: AppColors.primary),
                const SizedBox(height: 8),
                Text('Growth Level: $frameIndex', style: AppTypography.labelSmall),
              ],
            ),
          ),
          // Progress Bubble
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.secondary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'PROGRAM PROGRESS: ${(overallProgress * 100).toInt()}%',
                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== DAYS SELECTOR =====
  Widget _buildDaysSelector(int currentDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '30-Day Program',
            style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: 30,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSelected = day == currentDay;
              
              return GestureDetector(
                onTap: () => ref.read(taskTrackerProvider.notifier).setCurrentDay(day),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'D',
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.black : AppColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '$day',
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected ? Colors.black : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===== MISSION LIST =====
  List<Widget> _buildTasksList(List<Task> tasks, int day) {
    if (tasks.isEmpty) {
      return [const Padding(padding: EdgeInsets.all(20), child: Text('No missions for this day.'))];
    }

    return tasks.map((task) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => ref.read(taskTrackerProvider.notifier).toggleTask(day, task.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: task.isCompleted ? AppColors.secondary.withValues(alpha: 0.05) : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: task.isCompleted ? AppColors.secondary.withValues(alpha: 0.3) : AppColors.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Custom Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.secondary : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.isCompleted 
                      ? const Icon(Icons.check, color: Colors.black, size: 16)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: task.isCompleted ? AppColors.onSurfaceVariant : AppColors.onSurface,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (!task.isCompleted)
                  Text(
                    '+${task.xpReward} XP',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ===== PROGRESS STATS =====
  Widget _buildProgressStats(String percent, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Consistency', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                Text('$percent%', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
