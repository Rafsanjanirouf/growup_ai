import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserStats {
  final int streak;
  final int coins;
  final int? lastFaceScore;
  final Map<String, int> scoreBreakdown;

  UserStats({
    required this.streak,
    required this.coins,
    this.lastFaceScore,
    this.scoreBreakdown = const {},
  });

  UserStats copyWith({
    int? streak,
    int? coins,
    int? lastFaceScore,
    Map<String, int>? scoreBreakdown,
  }) {
    return UserStats(
      streak: streak ?? this.streak,
      coins: coins ?? this.coins,
      lastFaceScore: lastFaceScore ?? this.lastFaceScore,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
    );
  }
}

class UserStatsNotifier extends StateNotifier<UserStats> {
  UserStatsNotifier() : super(UserStats(streak: 0, coins: 50));

  void updateScore(int total, Map<String, int> breakdown) {
    state = state.copyWith(
      lastFaceScore: total,
      scoreBreakdown: breakdown,
    );
  }

  void addCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }

  void incrementStreak() {
    state = state.copyWith(streak: state.streak + 1);
  }
}

final userStatsProvider = StateNotifierProvider<UserStatsNotifier, UserStats>((ref) {
  return UserStatsNotifier();
});
