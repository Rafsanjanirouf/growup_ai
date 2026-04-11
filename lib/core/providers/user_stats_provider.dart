import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class UserStats {
  final int coins;
  final int streak;
  final int freeScansLeft;
  final int lastFaceScore;
  final int level;
  final int xp;

  UserStats({
    required this.coins,
    required this.streak,
    required this.freeScansLeft,
    required this.lastFaceScore,
    this.level = 1,
    this.xp = 0,
  });

  UserStats copyWith({
    int? coins,
    int? streak,
    int? freeScansLeft,
    int? lastFaceScore,
    int? level,
    int? xp,
  }) {
    return UserStats(
      coins: coins ?? this.coins,
      streak: streak ?? this.streak,
      freeScansLeft: freeScansLeft ?? this.freeScansLeft,
      lastFaceScore: lastFaceScore ?? this.lastFaceScore,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }
}

class UserStatsNotifier extends Notifier<UserStats> {
  static const _coinsKey = 'user_coins';
  static const _streakKey = 'user_streak';
  static const _freeScansKey = 'free_scans_left';
  static const _lastFaceScoreKey = 'last_face_score';
  static const _lastLoginDateKey = 'last_login_date';
  static const _levelKey = 'user_level';
  static const _xpKey = 'user_xp';

  late SharedPreferences _prefs;

  @override
  UserStats build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _initializeDailyStats();
    
    return UserStats(
      coins: _prefs.getInt(_coinsKey) ?? 0,
      streak: _prefs.getInt(_streakKey) ?? 1,
      freeScansLeft: _prefs.getInt(_freeScansKey) ?? 1,
      lastFaceScore: _prefs.getInt(_lastFaceScoreKey) ?? 0,
      level: _prefs.getInt(_levelKey) ?? 1,
      xp: _prefs.getInt(_xpKey) ?? 0,
    );
  }

  void _initializeDailyStats() {
    final now = DateTime.now();
    final todayString = "${now.year}-${now.month}-${now.day}";
    final lastLoginDate = _prefs.getString(_lastLoginDateKey) ?? "";

    if (lastLoginDate != todayString) {
      // New day, reset scans and update login
      _prefs.setString(_lastLoginDateKey, todayString);
      _prefs.setInt(_freeScansKey, 1);
      
      // Streak logic could be here (mock simple increment for now if consecutive day, or 1 if broken)
      // We will just keep it simple
    }
  }

  Future<void> addCoins(int amount) async {
    final newCoins = state.coins + amount;
    await _prefs.setInt(_coinsKey, newCoins);
    state = state.copyWith(coins: newCoins);
  }

  Future<bool> deductCoins(int amount) async {
    if (state.coins >= amount) {
      final newCoins = state.coins - amount;
      await _prefs.setInt(_coinsKey, newCoins);
      state = state.copyWith(coins: newCoins);
      return true;
    }
    return false;
  }

  Future<void> consumeFreeScan() async {
    if (state.freeScansLeft > 0) {
      final newScans = state.freeScansLeft - 1;
      await _prefs.setInt(_freeScansKey, newScans);
      state = state.copyWith(freeScansLeft: newScans);
    }
  }

  Future<void> updateFaceScore(int score) async {
    await _prefs.setInt(_lastFaceScoreKey, score);
    state = state.copyWith(lastFaceScore: score);
  }

  Future<void> addXP(int amount) async {
    final newXP = state.xp + amount;
    await _prefs.setInt(_xpKey, newXP);
    state = state.copyWith(xp: newXP);
  }

  Future<void> updateLevel(int newLevel) async {
    await _prefs.setInt(_levelKey, newLevel);
    state = state.copyWith(level: newLevel);
  }
}

final userStatsProvider = NotifierProvider<UserStatsNotifier, UserStats>(() {
  return UserStatsNotifier();
});
