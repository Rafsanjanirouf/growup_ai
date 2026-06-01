import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

    if (taskState.isLoading || taskState.dailyTasks.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedDate = taskState.selectedDate;
    final normalizedSelectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final tasksForDay = taskState.dailyTasks[normalizedSelectedDate] ?? [];
    
    // Filter by selected category
    final filteredTasks = tasksForDay.where((t) => t.category == taskState.selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: Column(
        children: [
          // ===== PAGE TITLE =====
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Complete Tasks & Grow Tree',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // ===== GROWTH TREE HERO SECTION =====
          _buildTreeHero(taskState.treeFrame, taskState.overallProgress),

          // ===== CALENDAR STRIP =====
          _buildCalendarStrip(taskState),

          // ===== TAB TOGGLE (Habit vs Regular) =====
          _buildCategoryTabs(taskState),

          // ===== TASK LIST =====
          Expanded(
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return _TaskCard(
                        task: filteredTasks[index],
                        date: normalizedSelectedDate,
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(TaskTrackerState state) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // Get the week dates (from generated map)
    final dates = state.dailyTasks.keys.toList()..sort();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date == state.selectedDate;
          final isToday = date == normalizedToday;
          final isPast = date.isBefore(normalizedToday);
          
          final tasks = state.dailyTasks[date] ?? [];
          final allCompleted = tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

          return GestureDetector(
            onTap: () => ref.read(taskTrackerProvider.notifier).setSelectedDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary 
                      : isPast && !allCompleted ? AppColors.primary.withValues(alpha: 0.3) : Colors.white10,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status Dot
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast && !allCompleted 
                          ? AppColors.primary // Missed
                          : (isToday || allCompleted) ? Colors.green : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(TaskTrackerState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabButton('Habit', TaskCategory.habit, state.selectedCategory),
          _buildTabButton('Regular', TaskCategory.regular, state.selectedCategory),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, TaskCategory category, TaskCategory selected) {
    final isActive = category == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(taskTrackerProvider.notifier).setCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('All tasks completed for this category!', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  // ===== GROWTH TREE HERO =====
  Widget _buildTreeHero(int frameIndex, double overallProgress) {
    final frameString = frameIndex.toString().padLeft(3, '0');
    
    return Container(
      height: 240, // Slightly more compact to fit with calendar
      width: double.infinity,
      decoration: const BoxDecoration(
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
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Growth Image
          Image.asset(
            'assets/images/tree/ezgif-frame-$frameString.png',
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.park_rounded, size: 60, color: AppColors.primary),
                const SizedBox(height: 8),
                Text('Lvl $frameIndex', style: AppTypography.labelSmall.copyWith(color: Colors.white24)),
              ],
            ),
          ),
          // Progress Bubble
          Positioned(
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.secondary, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    'GROWTH: ${(overallProgress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  final Task task;
  final DateTime date;

  const _TaskCard({required this.task, required this.date});

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  bool _isExpanded = false;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.task.durationSeconds;
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() => _isTimerRunning = false);
        _completeTask();
      }
    });
  }

  void _completeTask() {
    ref.read(taskTrackerProvider.notifier).toggleTask(widget.date, widget.task.id);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.date.year == DateTime.now().year && 
                   widget.date.month == DateTime.now().month && 
                   widget.date.day == DateTime.now().day;
    
    final tagColor = _getTagColor(widget.task.timeTag);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.task.isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.task.timeTag.name.toUpperCase(),
                      style: TextStyle(color: tagColor, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        color: widget.task.isCompleted ? Colors.white38 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  // Completion Button
                  if (isToday && !widget.task.isCompleted)
                    _buildActionButton()
                  else if (widget.task.isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24)
                  else
                    const Icon(Icons.lock_outline, color: Colors.white10, size: 20),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (widget.task.type == TaskType.timer) {
      if (_isTimerRunning) {
        return Text(
          '${(_secondsLeft ~/ 60)}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        );
      }
      return GestureDetector(
        onTap: _startTimer,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow, color: Colors.black, size: 16),
        ),
      );
    }

    return GestureDetector(
      onTap: _completeTask,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getTagColor(TaskTimeTag tag) {
    switch (tag) {
      case TaskTimeTag.morning: return Colors.orangeAccent;
      case TaskTimeTag.noon: return Colors.yellow;
      case TaskTimeTag.night: return Colors.purpleAccent;
    }
  }
}
