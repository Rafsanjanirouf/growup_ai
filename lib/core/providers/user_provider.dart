import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider for SharedPreferences overridden at startup in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main.dart');
});

// Model to represent user state
class UserState {
  final String name;
  final int age;
  final String gender;
  final List<String> goals;
  final String skinType;
  final String budget;
  final int streak;
  final double auraScore;
  final bool isPro;
  final bool onboardingCompleted;
  final String coachLanguage;
  
  final String? morningTime;
  final String? noonTime;
  final String? eveningTime;
  final String? nightTime;
  
  final bool hasLostStreak;
  final int lostStreakCount;

  String get effectiveMorningTime => morningTime ?? '06:00';
  String get effectiveNoonTime => noonTime ?? '12:00';
  String get effectiveEveningTime => eveningTime ?? '18:00';
  String get effectiveNightTime => nightTime ?? '20:00';

  UserState({
    this.name = '',
    this.age = 18,
    this.gender = 'Male',
    this.goals = const [],
    this.skinType = 'Oily',
    this.budget = 'Basic',
    this.streak = 0,
    this.auraScore = 0.0,
    this.isPro = false,
    this.onboardingCompleted = false,
    this.coachLanguage = 'English',
    this.morningTime,
    this.noonTime,
    this.eveningTime,
    this.nightTime,
    this.hasLostStreak = false,
    this.lostStreakCount = 0,
  });

  UserState copyWith({
    String? name,
    int? age,
    String? gender,
    List<String>? goals,
    String? skinType,
    String? budget,
    int? streak,
    double? auraScore,
    bool? isPro,
    bool? onboardingCompleted,
    String? coachLanguage,
    String? morningTime,
    String? noonTime,
    String? eveningTime,
    String? nightTime,
    bool? hasLostStreak,
    int? lostStreakCount,
  }) {
    return UserState(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goals: goals ?? this.goals,
      skinType: skinType ?? this.skinType,
      budget: budget ?? this.budget,
      streak: streak ?? this.streak,
      auraScore: auraScore ?? this.auraScore,
      isPro: isPro ?? this.isPro,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      coachLanguage: coachLanguage ?? this.coachLanguage,
      morningTime: morningTime ?? this.morningTime,
      noonTime: noonTime ?? this.noonTime,
      eveningTime: eveningTime ?? this.eveningTime,
      nightTime: nightTime ?? this.nightTime,
      hasLostStreak: hasLostStreak ?? this.hasLostStreak,
      lostStreakCount: lostStreakCount ?? this.lostStreakCount,
    );
  }
}

// UserStateNotifier handles reading/writing data to local SharedPreferences
class UserStateNotifier extends StateNotifier<UserState> {
  final SharedPreferences _prefs;

  UserStateNotifier(this._prefs) : super(UserState()) {
    _loadState();
  }

  void _loadState() {
    final name = _prefs.getString('aura_name') ?? '';
    final age = _prefs.getInt('aura_age') ?? 18;
    final gender = _prefs.getString('aura_gender') ?? 'Male';
    final goals = _prefs.getStringList('aura_goals') ?? [];
    final skinType = _prefs.getString('aura_skintype') ?? 'Oily';
    final budget = _prefs.getString('aura_budget') ?? 'Basic';
    final streak = _prefs.getInt('aura_streak') ?? 0;
    final auraScore = _prefs.getDouble('aura_score') ?? 0.0;
    final isPro = _prefs.getBool('aura_ispro') ?? false;
    final onboardingCompleted = _prefs.getBool('aura_onboarded') ?? false;
    final coachLanguage = _prefs.getString('aura_coach_language') ?? 'English';
    
    final morningTime = _prefs.getString('aura_morning_time');
    final noonTime = _prefs.getString('aura_noon_time');
    final eveningTime = _prefs.getString('aura_evening_time');
    final nightTime = _prefs.getString('aura_night_time');

    state = UserState(
      name: name,
      age: age,
      gender: gender,
      goals: goals,
      skinType: skinType,
      budget: budget,
      streak: streak,
      auraScore: auraScore,
      isPro: isPro,
      onboardingCompleted: onboardingCompleted,
      coachLanguage: coachLanguage,
      morningTime: morningTime,
      noonTime: noonTime,
      eveningTime: eveningTime,
      nightTime: nightTime,
    );
  }

  Future<void> updateNotificationTimes({
    String? morningTime,
    String? noonTime,
    String? eveningTime,
    String? nightTime,
  }) async {
    if (morningTime != null) await _prefs.setString('aura_morning_time', morningTime);
    if (noonTime != null) await _prefs.setString('aura_noon_time', noonTime);
    if (eveningTime != null) await _prefs.setString('aura_evening_time', eveningTime);
    if (nightTime != null) await _prefs.setString('aura_night_time', nightTime);

    state = state.copyWith(
      morningTime: morningTime,
      noonTime: noonTime,
      eveningTime: eveningTime,
      nightTime: nightTime,
    );
  }

  Future<void> updateProfile({required String name, required int age, required String gender}) async {
    await _prefs.setString('aura_name', name);
    await _prefs.setInt('aura_age', age);
    await _prefs.setString('aura_gender', gender);
    state = state.copyWith(name: name, age: age, gender: gender);
  }

  Future<void> updateGoals(List<String> goals) async {
    await _prefs.setStringList('aura_goals', goals);
    state = state.copyWith(goals: goals);
  }

  Future<void> updateLifestyle({required String skinType, required String budget}) async {
    await _prefs.setString('aura_skintype', skinType);
    await _prefs.setString('aura_budget', budget);
    state = state.copyWith(skinType: skinType, budget: budget);
  }

  Future<void> updateLanguage(String language) async {
    await _prefs.setString('aura_coach_language', language);
    state = state.copyWith(coachLanguage: language);
  }

  Future<void> updateAuraScore(double score) async {
    await _prefs.setDouble('aura_score', score);
    state = state.copyWith(auraScore: score);
  }

  Future<void> setPro(bool isPro) async {
    await _prefs.setBool('aura_ispro', isPro);
    state = state.copyWith(isPro: isPro);
  }

  Future<void> incrementStreak() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nextStreak = state.streak + 1;
    await _prefs.setInt('aura_streak', nextStreak);
    await _prefs.setString('last_streak_date', todayStr);
    state = state.copyWith(streak: nextStreak);
    
    try {
      final firestoreService = FirestoreService();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await firestoreService.updateUser(user.uid, {
          'current_streak': nextStreak,
          'last_streak_date': todayStr,
        });
      }
    } catch (_) {}
  }

  /// Called on app open. Checks last streak increment date.
  /// - If missed a day (last_streak_date > yesterday), flags hasLostStreak to true.
  /// - Does NOT increment streak automatically.
  Future<void> checkAndUpdateStreak(String userId) async {
    try {
      final firestoreService = FirestoreService();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final userData = await firestoreService.getUserData(userId);
      final lastStreakDate = userData?['last_streak_date'] as String? ?? _prefs.getString('last_streak_date') ?? '';
      final savedStreak = (userData?['current_streak'] as num?)?.toInt() ?? _prefs.getInt('aura_streak') ?? 0;

      // Sync state with firestore if needed
      if (savedStreak != state.streak) {
        await _prefs.setInt('aura_streak', savedStreak);
        state = state.copyWith(streak: savedStreak);
      }

      if (lastStreakDate.isNotEmpty && savedStreak > 0) {
        final lastDate = DateFormat('yyyy-MM-dd').parse(lastStreakDate);
        final today = DateFormat('yyyy-MM-dd').parse(todayStr);
        final diffDays = today.difference(lastDate).inDays;

        if (diffDays > 1) {
          // Missed a day! Set flag to show Downgrade Dialog
          state = state.copyWith(
            hasLostStreak: true,
            lostStreakCount: savedStreak,
          );
        }
      }
    } catch (e) {
      debugPrint('checkAndUpdateStreak error: $e');
    }
  }

  Future<void> acknowledgeLostStreak() async {
    await _prefs.setInt('aura_streak', 0);
    state = state.copyWith(streak: 0, hasLostStreak: false, lostStreakCount: 0);

    try {
      final firestoreService = FirestoreService();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await firestoreService.updateUser(user.uid, {
          'current_streak': 0,
        });
      }
    } catch (_) {}
  }

  Future<void> setStreak(int streak) async {
    await _prefs.setInt('aura_streak', streak);
    state = state.copyWith(streak: streak);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('aura_onboarded', true);
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> resetState() async {
    await _prefs.clear();
    state = UserState();
  }
}

// Global user state provider
final userStateProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserStateNotifier(prefs);
});
