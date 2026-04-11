import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_stats_provider.dart';

final voiceGuideProvider = StateNotifierProvider<VoiceGuideNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VoiceGuideNotifier(prefs);
});

class VoiceGuideNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final FlutterTts _tts = FlutterTts();
  static const String _storageKey = 'is_voice_guide_enabled';

  VoiceGuideNotifier(this._prefs) : super(_prefs.getBool(_storageKey) ?? true) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5); // Calm, professional rate
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.8);
  }

  bool get isEnabled => state;

  Future<void> toggleVoiceGuide() async {
    state = !state;
    await _prefs.setBool(_storageKey, state);
    if (!state) {
      await _tts.stop();
    }
  }

  Future<void> speak(String text) async {
    if (state) {
      await _tts.stop();
      await _tts.speak(text);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
