import 'package:dio/dio.dart';

class OpenAIService {
  final Dio _dio = Dio();
  
  // PLACEHOLDER: Replace with your actual OpenAI Key
  static const String _apiKey = 'YOUR_OPENAI_API_KEY';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> getResponse(String userMessage) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content": "You are GrowUp Coach, a friendly AI self-improvement coach for young men. Respond in a motivating, practical, and concise way (max 150 words). Focus on grooming, style, jawline, skin, and mindset."
            },
            {"role": "user", "content": userMessage}
          ],
          "temperature": 0.7
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      } else {
        return 'I am having trouble connecting to the neural link. Try again soon, Alpha.';
      }
    } catch (e) {
      return 'Mocking Response: That is a great question about self-improvement! To improve your jawline, focus on mewing and reducing body fat.';
    }
  }
}
