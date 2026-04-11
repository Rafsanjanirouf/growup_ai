import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // PLACEHOLDER: Replace with your actual Gemini API Key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey,
          systemInstruction: Content.system(
            "You are GrowUp Coach, a friendly AI self-improvement coach for young men. "
            "Respond in a motivating, practical, and concise way (max 150 words). "
            "Focus on grooming, style, jawline, skin, and mindset. Detect user language and respond accordingly (Bengali/English)."
          ),
        );

  Future<String> getResponse(String userMessage) async {
    try {
      final content = [Content.text(userMessage)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'I am processing your transformation data. Try again, Alpha.';
    } catch (e) {
      // Mocking for testing if API key is missing
      return 'Mocking Gemini: Focus on consistent mewing and a clean diet for that sharp jawline. Keep grinding!';
    }
  }
}
