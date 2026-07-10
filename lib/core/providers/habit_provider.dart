import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';
import 'daily_progress_provider.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import 'package:intl/intl.dart';

class Habit {
  final String id;
  final String title;
  final String timeOfDay; // 'morning' | 'afternoon' | 'evening' | 'night'
  final String frequency; // 'daily' | 'weekly' | 'monthly'
  final bool isCompleted;
  final String icon;
  final String description;
  final bool isCustom;

  final int targetCount;
  final int currentCount;

  Habit({
    required this.id,
    required this.title,
    required this.timeOfDay,
    this.frequency = 'daily',
    this.isCompleted = false,
    required this.icon,
    required this.description,
    this.isCustom = false,
    this.targetCount = 1,
    this.currentCount = 0,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? timeOfDay,
    String? frequency,
    bool? isCompleted,
    String? icon,
    String? description,
    bool? isCustom,
    int? targetCount,
    int? currentCount,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      frequency: frequency ?? this.frequency,
      isCompleted: isCompleted ?? this.isCompleted,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timeOfDay': timeOfDay,
      'frequency': frequency,
      'isCompleted': isCompleted,
      'icon': icon,
      'description': description,
      'isCustom': isCustom,
      'targetCount': targetCount,
      'currentCount': currentCount,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      timeOfDay: json['timeOfDay'] as String,
      frequency: json['frequency'] as String? ?? 'daily',
      isCompleted: json['isCompleted'] as bool? ?? false,
      icon: json['icon'] as String,
      description: json['description'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 1,
      currentCount: json['currentCount'] as int? ?? 0,
    );
  }
}

class HabitStateNotifier extends StateNotifier<List<Habit>> {
  final SharedPreferences _prefs;
  final Ref _ref;
  final DateTime _currentDate;

  HabitStateNotifier(this._prefs, this._ref, this._currentDate) : super([]) {
    _loadHabits();
  }

  String get _dateKey => 'aura_tasks_${DateFormat('yyyy-MM-dd').format(_currentDate)}';

  void _loadHabits() {
    final habitsJson = _prefs.getString(_dateKey);
    List<Habit> todaysTasks = [];
    if (habitsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(habitsJson);
        todaysTasks = decoded.map((item) => Habit.fromJson(item)).toList();
      } catch (e) {
        // ignore parsing error
      }
    }

    // Merge daily custom tasks from master tasks
    final masterTasksJson = _prefs.getString('aura_master_tasks');
    if (masterTasksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(masterTasksJson);
        final masterTasks = decoded.map((item) => Habit.fromJson(item)).toList();
        for (var mt in masterTasks) {
          if (mt.frequency == 'daily' && !todaysTasks.any((t) => t.id == mt.id)) {
            todaysTasks.add(mt.copyWith(isCompleted: false, currentCount: 0));
          }
        }
      } catch (e) {
        // ignore parsing error
      }
    }

    state = todaysTasks;
    if (todaysTasks.isNotEmpty) {
      _saveHabits();
    }
    rescheduleReminders();
  }

  Future<bool> toggleHabit(String id) async {
    state = state.map((habit) {
      if (habit.id == id) {
        if (habit.isCompleted) {
          // Uncheck
          return habit.copyWith(currentCount: 0, isCompleted: false);
        } else {
          final newCount = habit.currentCount + 1;
          final isDone = newCount >= habit.targetCount;
          return habit.copyWith(currentCount: newCount, isCompleted: isDone);
        }
      }
      return habit;
    }).toList();

    await _saveHabits();
    rescheduleReminders();
    final didIncrement = _checkAndIncrementStreak();
    await _syncToFirestore();

    // Snapshot today's completion count
    final completed = state.where((h) => h.isCompleted).length;
    await _ref.read(dailyProgressProvider.notifier).updateToday(
      completed: completed,
      total: state.length,
    );
    
    return didIncrement;
  }

  Future<void> addCustomTask(Habit habit) async {
    state = [...state, habit];
    await _saveHabits();
    rescheduleReminders();
    _ref.read(masterHabitProvider.notifier).addTask(habit);
  }

  Future<void> editTask(Habit updatedHabit) async {
    state = state.map((h) => h.id == updatedHabit.id ? updatedHabit : h).toList();
    await _saveHabits();
    rescheduleReminders();
    _ref.read(masterHabitProvider.notifier).updateTask(updatedHabit);
  }

  Future<void> deleteTask(String id) async {
    state = state.where((h) => h.id != id).toList();
    await _saveHabits();
    rescheduleReminders();
    _ref.read(masterHabitProvider.notifier).deleteTask(id);
  }

  Future<void> setDynamicHabits(List<Habit> dynamicHabits) async {
    state = dynamicHabits;
    await _saveHabits();
    rescheduleReminders();
  }

  Future<void> replaceDynamicHabits(List<Habit> dynamicHabits) => setDynamicHabits(dynamicHabits);

  Future<void> generateAITasks(UserState user) async {
    final aiData = await GeminiService.generatePersonalizedTasks(
      age: user.age,
      gender: user.gender,
      skinType: user.skinType,
      goals: user.goals,
      budget: user.budget,
      language: user.coachLanguage,
    );

    if (aiData.isNotEmpty) {
      await generateTasksFromScan(aiData);
    } else {
      await generateTasksFromScan(null); // fallback
    }
  }

  Future<void> generateTasksFromScan(Map<String, dynamic>? scanAnalyticsData) async {
    List<Habit> generatedTasks = [];

    if (scanAnalyticsData != null) {
      void parseSection(List<dynamic>? items, String timeOfDay, String iconName, String prefix) {
        if (items == null) return;
        int idx = 1;
        for (var h in items) {
          generatedTasks.add(Habit(
            id: '${prefix}_$idx',
            title: h['title'] ?? 'Task',
            timeOfDay: timeOfDay,
            icon: iconName,
            description: h['desc'] ?? '',
          ));
          idx++;
        }
      }
      parseSection(scanAnalyticsData['morning_routine'], 'morning', 'wb_sunny', 'dm');
      parseSection(scanAnalyticsData['noon_routine'], 'noon', 'wb_twilight', 'da');
      parseSection(scanAnalyticsData['evening_routine'], 'evening', 'wb_iridescent', 'de');
      parseSection(scanAnalyticsData['night_routine'], 'night', 'nights_stay', 'dn');
    } else {
      // Fallback Default Tasks
      generatedTasks = [
        Habit(id: 'f1', title: 'Hydration Kickstart 💧', timeOfDay: 'morning', icon: 'water_drop', description: 'Drink 2 large glasses of warm water.', targetCount: 1),
        Habit(id: 'f2', title: 'Sleek Face Cleansing 🧼', timeOfDay: 'morning', icon: 'face', description: 'Gentle salicylic acid wash.', targetCount: 2),
        Habit(id: 'f3', title: 'Mewing Session 👅', timeOfDay: 'noon', icon: 'wb_twilight', description: 'Mew for 15 minutes.', targetCount: 3),
        Habit(id: 'f6', title: 'Grooming Touch-up ✨', timeOfDay: 'evening', icon: 'wb_iridescent', description: 'Quick mirror check.', targetCount: 1),
        Habit(id: 'f4', title: 'Deep Purification Cleanse 🌌', timeOfDay: 'night', icon: 'cleaning_services', description: 'Wash away pollutants.', targetCount: 1),
        Habit(id: 'f5', title: 'GrowUp AI Sleep Hygiene 💤', timeOfDay: 'night', icon: 'nights_stay', description: 'Ditch screens 30 mins before sleep.', targetCount: 1),
      ];
    }

    final existingCustomTasks = state.where((h) => h.isCustom).toList();

    // Save for Today
    state = [...generatedTasks, ...existingCustomTasks];
    await _saveHabits();
    rescheduleReminders();

    // Save for Tomorrow
    final tomorrow = _currentDate.add(const Duration(days: 1));
    final tomorrowKey = 'aura_tasks_${DateFormat('yyyy-MM-dd').format(tomorrow)}';
    final String encoded = jsonEncode(generatedTasks.map((e) => e.toJson()).toList());
    await _prefs.setString(tomorrowKey, encoded);
  }

  Future<void> rescheduleReminders() async {
    await NotificationService().cancelAll();
    _scheduleReminders(state);
  }

  void _scheduleReminders(List<Habit> tasks) {
    int idCounter = 1;
    final now = DateTime.now();
    final userState = _ref.read(userStateProvider);

    DateTime? parseTime(String timeString) {
      try {
        final parts = timeString.split(':');
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      } catch (e) {
        return null;
      }
    }

    final morningTime = parseTime(userState.effectiveMorningTime);
    final noonTime = parseTime(userState.effectiveNoonTime);
    final eveningTime = parseTime(userState.effectiveEveningTime);
    final nightTime = parseTime(userState.effectiveNightTime);

    for (var task in tasks) {
      if (task.isCompleted) continue;

      DateTime? scheduleTime;
      if (task.timeOfDay == 'morning') {
        scheduleTime = morningTime;
      } else if (task.timeOfDay == 'noon') {
        scheduleTime = noonTime;
      } else if (task.timeOfDay == 'evening') {
        scheduleTime = eveningTime;
      } else if (task.timeOfDay == 'night') {
        scheduleTime = nightTime;
      }

      if (scheduleTime != null) {
        if (scheduleTime.isBefore(now)) {
          scheduleTime = scheduleTime.add(const Duration(days: 1));
        }
        NotificationService().scheduleTaskReminder(
          id: idCounter++,
          title: 'Time for your ${task.timeOfDay} routine!',
          body: 'Task: ${task.title}',
          scheduledTime: scheduleTime,
        );
      }
    }
  }

  Future<void> _saveHabits() async {
    final String encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await _prefs.setString(_dateKey, encoded);
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final tasksList = state.map((t) => {
        'id': t.id,
        'title': t.title,
        'timeOfDay': t.timeOfDay,
        'isCompleted': t.isCompleted,
        'targetCount': t.targetCount,
        'currentCount': t.currentCount,
        'icon': t.icon,
      }).toList();

      await FirestoreService().saveDailyTasks(
        userId: user.uid,
        date: _currentDate,
        tasksList: tasksList,
      );
    } catch (e) {
      // ignore
    }
  }

  /// Increments streak only once per calendar day.
  /// Triggered when the user completes at least one task.
  /// Uses SharedPreferences key 'last_streak_date' (yyyy-MM-dd) as a guard.
  bool _checkAndIncrementStreak() {
    if (state.isEmpty) return false;
    final anyCompleted = state.any((habit) => habit.isCompleted);
    if (!anyCompleted) return false;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastIncrDate = _prefs.getString('last_streak_date') ?? '';
    if (lastIncrDate == today) return false; // Already incremented today

    // Mark today as done and increment
    _ref.read(userStateProvider.notifier).incrementStreak();
    return true;
  }
}

final habitStateProvider = StateNotifierProvider<HabitStateNotifier, List<Habit>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider); // assuming sharedPreferencesProvider is correctly provided globally
  return HabitStateNotifier(prefs, ref, DateTime.now());
});

// Alias
final habitProvider = habitStateProvider;

// ── Master Habits Provider ──
class MasterHabitStateNotifier extends StateNotifier<List<Habit>> {
  final SharedPreferences _prefs;

  MasterHabitStateNotifier(this._prefs) : super([]) {
    _loadTasks();
  }

  static const _key = 'aura_master_tasks';

  void _loadTasks() {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        state = decoded.map((item) => Habit.fromJson(item)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> addTask(Habit task) async {
    // Avoid duplicates if added from daily tasks logic
    if (state.any((t) => t.id == task.id)) return;
    state = [...state, task];
    await _saveTasks();
  }

  Future<void> updateTask(Habit task) async {
    state = state.map((t) => t.id == task.id ? task : t).toList();
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _saveTasks();
  }

  Future<void> _saveTasks() async {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }
}

final masterHabitProvider = StateNotifierProvider<MasterHabitStateNotifier, List<Habit>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MasterHabitStateNotifier(prefs);
});