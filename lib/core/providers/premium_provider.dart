import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false); // Default to false for demonstrating gating

  void togglePremium() {
    state = !state;
  }

  void setPremium(bool value) {
    state = value;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
