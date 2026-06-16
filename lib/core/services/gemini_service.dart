import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../providers/habit_provider.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: ApiKeys.geminiApiKey);
  /// Structured system prompt — returns ALL fields from database_schema.md scan_history table.
  static String analyticsSystemPrompt(String language) => '''
You are Aura AI, an expert Lookmaxxing and aesthetics doctor coach.
You will receive geometric scores from ML Kit. Your job is to visually inspect the photo, confirm the geometry, and provide a deep, highly detailed diagnostics report.

IMPORTANT RULE: You MUST write ALL text descriptions, titles, messages, and items exclusively in the $language language. 
Make sure your explanations explicitly point out the "Strong section" (strong points) and "Weak section" (weak points) so that it is fully understandable by the user.

MUST INCLUDE 10+ IMPORTANT REPORT INSIGHTS spread across the categories.

Return ONLY raw JSON. No markdown, no backticks.

{
  "analytics": {
    "markers": [
      {"title": "[Title in $language]", "message": "[Message in $language]", "top": 90.0, "left": 155.0},
      {"title": "[Title in $language]", "message": "[Message in $language]", "top": 190.0, "left": 210.0}
    ],
    "reports": {
      "aura": { "score": "86%", "items": ["[Aura insight 1 in $language]", "[Aura insight 2 in $language]"] },
      "structure": { "score": "86%", "items": ["[Jawline insight 1 in $language]", "[Jawline insight 2 in $language]"] },
      "skin": { "score": "78%", "items": ["[Skin insight 1 in $language]", "[Skin insight 2 in $language]"] },
      "eyes": { "score": "80%", "items": ["[Eye insight 1 in $language]", "[Eye insight 2 in $language]"] },
      "posture": { "score": "94%", "items": ["[Posture insight 1 in $language]", "[Posture insight 2 in $language]"] }
      // The sum of all items in all reports MUST BE AT LEAST 10+!
    }
  },
  "morning_routine": [
    {"title": "[Routine title in $language] 💧", "desc": "[Routine description in $language]"}
  ],
  "noon_routine": [
    {"title": "[Routine title in $language] ☀️", "desc": "[Routine description in $language]"}
  ],
  "evening_routine": [
    {"title": "[Routine title in $language] 🌇", "desc": "[Routine description in $language]"}
  ],
  "night_routine": [
    {"title": "[Routine title in $language] 🌌", "desc": "[Routine description in $language]"}
  ]
}
''';

  static Future<Map<String, dynamic>> generateAnalytics(String imagePath, Map<String, dynamic> mlKitScores, {String language = 'English'}) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      systemInstruction: Content.system(analyticsSystemPrompt(language)),
    );

    final prompt = Content.multi([
      TextPart('Here are the base ML Kit Geometric Scores: ${jsonEncode(mlKitScores)}. Please visually analyze the face and return the JSON diagnostics with 10+ specific improvement reports.'),
      DataPart('image/webp', imageBytes),
    ]);

    final response = await model.generateContent([prompt]);
    final rawText = response.text ?? '';

    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Parses raw Gemini JSON into a list of Habit objects for the habit provider.
  static List<Habit> parseRoutineJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      final List<Habit> habits = [];

      void parseSection(List<dynamic>? items, String timeOfDay, String iconName, String prefix) {
        if (items == null) return;
        int idx = 1;
        for (var h in items) {
          habits.add(Habit(
            id: '${prefix}_$idx',
            title: h['title'] ?? 'Task',
            timeOfDay: timeOfDay,
            icon: iconName,
            description: h['desc'] ?? '',
          ));
          idx++;
        }
      }

      parseSection(decoded['morning_routine'],   'morning',   'wb_sunny',     'dm');
      parseSection(decoded['afternoon_routine'], 'afternoon', 'bolt',         'da');
      parseSection(decoded['night_routine'],     'night',     'nights_stay',  'dn');

      return habits;
    } catch (e) {
      debugPrint('GeminiService.parseRoutineJson error: $e');
      return [];
    }
  }

  /// Safe double extractor from dynamic JSON value.
  static double safeDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return fallback;
  }

  /// Safe string extractor.
  static String safeString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    return val.toString();
  }

  /// Safe map extractor.
  static Map<String, dynamic> safeMap(dynamic val) {
    if (val is Map<String, dynamic>) return val;
    return {};
  }

  /// Safe list-of-strings extractor.
  static List<String> safeStringList(dynamic val) {
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }

  // ══ CHAT WITH COACH ═════════════════════════════════════════════════════════

  /// Sends a message to the Gemini API, maintaining chat history and enforcing a language.
  /// Returns a Map with 'text' (the generated response) and 'tokens' (the token usage).
  static Future<Map<String, dynamic>> chatWithCoach({
    required List<Map<String, dynamic>> history,
    required String newMessage,
    required String language,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _apiKey,
        systemInstruction: Content.system(
            'You are Aura AI, a highly knowledgeable and supportive personal Lookmaxxing, Glow-up, and Aesthetics Coach. '
            'You give brief, encouraging, and highly specific advice on skin care, mewing, posture, etc. '
            'IMPORTANT RULE: You MUST write your entire response exclusively in the $language language.'
        ),
      );

      final chatHistory = history.map((msg) {
        final isUser = msg['isUser'] as bool;
        final text = msg['text'] as String;
        return Content(isUser ? 'user' : 'model', [TextPart(text)]);
      }).toList();

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(newMessage));
      
      final text = response.text ?? 'Sorry, I could not generate a response.';
      final exactTokens = response.usageMetadata?.totalTokenCount;
      final estimatedTokens = ((newMessage.length + text.length) / 4).round();
      
      return {
        'text': text,
        'tokens': exactTokens ?? estimatedTokens,
      };
    } catch (e) {
      debugPrint('GeminiService.chatWithCoach error: $e');
      return {
        'text': 'I am currently unavailable due to a network error. Please try again.',
        'tokens': 0,
      };
    }
  }
}
