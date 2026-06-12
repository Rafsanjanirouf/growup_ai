import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ─── Model ────────────────────────────────────────────────────────────────────

class DailyProgress {
  final String dateKey;   // 'yyyy-MM-dd'
  final DateTime date;
  final int completed;
  final int total;

  DailyProgress({
    required this.dateKey,
    required this.date,
    required this.completed,
    required this.total,
  });

  double get percentage => total > 0 ? completed / total : 0.0;

  String get label {
    // Returns short day label e.g. 'Mon', 'Tue'
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'date': date.toIso8601String(),
        'completed': completed,
        'total': total,
      };

  factory DailyProgress.fromJson(Map<String, dynamic> json) => DailyProgress(
        dateKey: json['dateKey'] as String,
        date: DateTime.parse(json['date'] as String),
        completed: json['completed'] as int,
        total: json['total'] as int,
      );

  static String keyFor(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class DailyProgressNotifier extends StateNotifier<List<DailyProgress>> {
  final SharedPreferences _prefs;

  DailyProgressNotifier(this._prefs) : super([]) {
    _load();
  }

  static const _key = 'daily_progress_v1';

  void _load() {
    final raw = _prefs.getStringList(_key) ?? [];
    state = raw
        .map((s) => DailyProgress.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
  }

  Future<void> _save() async {
    await _prefs.setStringList(
      _key,
      state.map((d) => jsonEncode(d.toJson())).toList(),
    );
  }

  /// Call this every time a habit is toggled to update today's snapshot.
  Future<void> updateToday({required int completed, required int total}) async {
    final todayKey = DailyProgress.keyFor(DateTime.now());
    final updated = state.where((d) => d.dateKey != todayKey).toList();
    updated.add(DailyProgress(
      dateKey: todayKey,
      date: DateTime.now(),
      completed: completed,
      total: total,
    ));
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = updated;
    await _save();

    // Track to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirestoreService().saveDailyProgress(
        userId: user.uid,
        dateKey: todayKey,
        completedCount: completed,
        totalCount: total,
      );
    }
  }

  /// Seeds demo data for the past 7 days if no real data exists.
  Future<void> seedDemoData() async {
    if (state.length >= 7) return;
    final now = DateTime.now();
    final existingKeys = state.map((d) => d.dateKey).toSet();

    final demos = <DailyProgress>[];
    final completions = [7, 5, 9, 6, 9, 4, 8]; // demo pattern
    for (int i = 7; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DailyProgress.keyFor(day);
      if (!existingKeys.contains(key)) {
        demos.add(DailyProgress(
          dateKey: key,
          date: day,
          completed: completions[7 - i],
          total: 9,
        ));
      }
    }

    if (demos.isEmpty) return;
    final merged = [...state, ...demos];
    merged.sort((a, b) => b.date.compareTo(a.date));
    state = merged;
    await _save();
  }

  /// Syncs real data from Firestore.
  Future<void> syncFromFirestore(List<DailyProgress> remoteData) async {
    if (remoteData.isEmpty) return;
    
    final existingKeys = state.map((d) => d.dateKey).toSet();
    final merged = [...state];
    
    for (final remote in remoteData) {
      if (!existingKeys.contains(remote.dateKey)) {
        merged.add(remote);
      } else {
        // Update existing if needed
        final index = merged.indexWhere((d) => d.dateKey == remote.dateKey);
        if (index != -1 && merged[index].completed < remote.completed) {
          merged[index] = remote;
        }
      }
    }
    
    merged.sort((a, b) => b.date.compareTo(a.date));
    state = merged;
    await _save();
  }

  /// Returns the last N days of records (padded with zeros if missing).
  List<DailyProgress> lastNDays(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final day = now.subtract(Duration(days: n - 1 - i));
      final key = DailyProgress.keyFor(day);
      return state.firstWhere(
        (d) => d.dateKey == key,
        orElse: () => DailyProgress(
          dateKey: key,
          date: day,
          completed: 0,
          total: 9,
        ),
      );
    });
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final dailyProgressProvider =
    StateNotifierProvider<DailyProgressNotifier, List<DailyProgress>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailyProgressNotifier(prefs);
});
