import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_stats_provider.dart';

class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final int xpReward;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.xpReward = 50,
  });

  Task copyWith({bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward,
    );
  }
}

class TaskTrackerState {
  final int currentDay; // 1-30
  final Map<int, List<Task>> days; // Day -> List of Tasks
  final bool isLoading;

  TaskTrackerState({
    required this.currentDay,
    required this.days,
    this.isLoading = false,
  });

  double get overallProgress {
    int totalTasks = 0;
    int completedTasks = 0;
    
    days.forEach((day, tasks) {
      totalTasks += tasks.length;
      completedTasks += tasks.where((t) => t.isCompleted).length;
    });

    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  int get treeFrame {
    // Mapping total progress to 82 frames (1-82)
    int frame = (overallProgress * 81).round() + 1;
    if (frame > 82) frame = 82;
    if (frame < 1) frame = 1;
    return frame;
  }

  TaskTrackerState copyWith({
    int? currentDay,
    Map<int, List<Task>>? days,
    bool? isLoading,
  }) {
    return TaskTrackerState(
      currentDay: currentDay ?? this.currentDay,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TaskTrackerNotifier extends StateNotifier<TaskTrackerState> {
  final Ref ref;
  late SharedPreferences _prefs;
  static const _currentDayKey = 'program_current_day';

  TaskTrackerNotifier(this.ref) : super(TaskTrackerState(currentDay: 1, days: {}, isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    _prefs = ref.watch(sharedPreferencesProvider);
    _loadState();
  }

  void _loadState() {
    // Initialize standard 30-day missions
    final Map<int, List<Task>> initialDays = {};
    for (int i = 1; i <= 30; i++) {
      initialDays[i] = [
        Task(id: 'task_${i}_1', title: 'Face Yoga (10 min)'),
        Task(id: 'task_${i}_2', title: 'Hydration Challenge'),
        Task(id: 'task_${i}_3', title: 'Skincare Routine'),
        Task(id: 'task_${i}_4', title: 'Meditation (5 min)'),
        Task(id: 'task_${i}_5', title: 'Daily Workout'),
      ];
    }

    // Load from memory (Simulated persistence for now, could use JSON in prefs)
    final savedDay = _prefs.getInt(_currentDayKey) ?? 1;
    
    state = TaskTrackerState(
      currentDay: savedDay,
      days: initialDays,
      isLoading: false,
    );
  }

  void toggleTask(int day, String taskId) {
    if (state.days.containsKey(day)) {
      final tasks = state.days[day]!;
      final updatedTasks = tasks.map((t) {
        if (t.id == taskId) {
          final newState = !t.isCompleted;
          if (newState) {
            // Reward XP on completion
            ref.read(userStatsProvider.notifier).addXP(t.xpReward);
          }
          return t.copyWith(isCompleted: newState);
        }
        return t;
      }).toList();

      final newDays = Map<int, List<Task>>.from(state.days);
      newDays[day] = updatedTasks;
      
      state = state.copyWith(days: newDays);
      _checkDayCompletion(day);
    }
  }

  void _checkDayCompletion(int day) {
    // Logic to increment day if all tasks completed, or just track progress
    // For now, let the user manually switch days or track overall
  }

  void setCurrentDay(int day) {
    if (day >= 1 && day <= 30) {
      state = state.copyWith(currentDay: day);
      _prefs.setInt(_currentDayKey, day);
    }
  }
}

final taskTrackerProvider = StateNotifierProvider<TaskTrackerNotifier, TaskTrackerState>((ref) {
  return TaskTrackerNotifier(ref);
});
