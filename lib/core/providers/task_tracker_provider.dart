import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_stats_provider.dart';

enum TaskTimeTag { morning, noon, night }
enum TaskType { simple, timer }
enum TaskCategory { habit, regular }

class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final int xpReward;
  final TaskTimeTag timeTag;
  final TaskType type;
  final TaskCategory category;
  final int durationSeconds;

  Task({
    required this.id,
    required this.title,
    this.description = 'Complete this task to improve your facial aesthetics and grow your tree.',
    this.isCompleted = false,
    this.xpReward = 50,
    this.timeTag = TaskTimeTag.morning,
    this.type = TaskType.simple,
    this.category = TaskCategory.habit,
    this.durationSeconds = 0,
  });

  Task copyWith({bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward,
      timeTag: timeTag,
      type: type,
      category: category,
      durationSeconds: durationSeconds,
    );
  }
}

class TaskTrackerState {
  final DateTime selectedDate;
  final Map<DateTime, List<Task>> dailyTasks;
  final bool isLoading;
  final TaskCategory selectedCategory;

  TaskTrackerState({
    required this.selectedDate,
    required this.dailyTasks,
    this.isLoading = false,
    this.selectedCategory = TaskCategory.habit,
  });

  double get overallProgress {
    int totalTasks = 0;
    int completedTasks = 0;
    
    dailyTasks.forEach((date, tasks) {
      totalTasks += tasks.length;
      completedTasks += tasks.where((t) => t.isCompleted).length;
    });

    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  int get treeFrame {
    int frame = (overallProgress * 81).round() + 1;
    if (frame > 82) frame = 82;
    if (frame < 1) frame = 1;
    return frame;
  }

  TaskTrackerState copyWith({
    DateTime? selectedDate,
    Map<DateTime, List<Task>>? dailyTasks,
    bool? isLoading,
    TaskCategory? selectedCategory,
  }) {
    return TaskTrackerState(
      selectedDate: selectedDate ?? this.selectedDate,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class TaskTrackerNotifier extends StateNotifier<TaskTrackerState> {
  final Ref ref;

  TaskTrackerNotifier(this.ref) 
    : super(TaskTrackerState(
        selectedDate: DateTime.now(), 
        dailyTasks: {}, 
        isLoading: true
      )) {
    _init();
  }

  Future<void> _init() async {
    _loadState();
  }

  void _loadState() {
    final Map<DateTime, List<Task>> tasks = {};
    final today = DateTime.now();
    
    // Generate tasks for 7 days (3 past, today, 3 future)
    for (int i = -3; i <= 3; i++) {
      final date = DateTime(today.year, today.month, today.day + i);
      tasks[date] = [
        Task(
          id: 'h1_$i', 
          title: 'Morning Mewing', 
          timeTag: TaskTimeTag.morning, 
          type: TaskType.timer, 
          durationSeconds: 300,
          category: TaskCategory.habit,
        ),
        Task(
          id: 'r1_$i', 
          title: 'Face Massage', 
          timeTag: TaskTimeTag.noon, 
          type: TaskType.simple,
          category: TaskCategory.regular,
        ),
        Task(
          id: 'h2_$i', 
          title: 'Skincare Routine', 
          timeTag: TaskTimeTag.night, 
          type: TaskType.simple,
          category: TaskCategory.habit,
        ),
        Task(
          id: 'r2_$i', 
          title: 'Jawline Workout', 
          timeTag: TaskTimeTag.night, 
          type: TaskType.timer, 
          durationSeconds: 600,
          category: TaskCategory.regular,
        ),
      ];
    }
    
    state = TaskTrackerState(
      selectedDate: today,
      dailyTasks: tasks,
      isLoading: false,
    );
  }

  void toggleTask(DateTime date, String taskId) {
    // Only allow editing for the current day
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    if (!isToday) return;

    if (state.dailyTasks.containsKey(date)) {
      final tasks = state.dailyTasks[date]!;
      final updatedTasks = tasks.map((t) {
        if (t.id == taskId) {
          final newState = !t.isCompleted;
          if (newState) ref.read(userStatsProvider.notifier).addXP(t.xpReward);
          return t.copyWith(isCompleted: newState);
        }
        return t;
      }).toList();

      final newDailyTasks = Map<DateTime, List<Task>>.from(state.dailyTasks);
      newDailyTasks[date] = updatedTasks;
      
      state = state.copyWith(dailyTasks: newDailyTasks);
    }
  }

  void setCategory(TaskCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}

final taskTrackerProvider = StateNotifierProvider<TaskTrackerNotifier, TaskTrackerState>((ref) {
  return TaskTrackerNotifier(ref);
});
