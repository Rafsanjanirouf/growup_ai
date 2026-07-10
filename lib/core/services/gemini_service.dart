import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dio/dio.dart';
import '../config/api_keys.dart';
import '../providers/habit_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class GeminiService {
  static Future<void> _trackUsage(String category, int tokens) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final dateKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      await FirestoreService().trackAiUsage(
        userId: user.uid,
        dateKey: dateKey,
        category: category,
        tokensUsed: tokens,
      );
    } catch (e) {
      debugPrint('GeminiService._trackUsage error: $e');
    }
  }
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: ApiKeys.geminiApiKey);
  /// Structured system prompt — returns ALL fields from database_schema.md scan_history table.
  static String analyticsSystemPrompt(String language) => '''
You are GrowUp AI, an expert Lookmaxxing and aesthetics doctor coach.
You will receive geometric scores from ML Kit. Your job is to visually inspect the photo, confirm the geometry, and provide a deep, highly detailed diagnostics report.

IMPORTANT RULE: You MUST write ALL text descriptions, titles, messages, and items exclusively in the $language language. 
Make sure your explanations explicitly point out the "Strong section" (strong points) and "Weak section" (weak points) so that it is fully understandable by the user.

MUST INCLUDE 10+ IMPORTANT REPORT INSIGHTS spread across the categories.

Return ONLY raw JSON. No markdown, no backticks.

{
  "overall_ai_face_score": 86.5,
  "face_shape": "Diamond",
  "face_symmetry": 85.0,
  "skin_health_score": 78.0,
  "acne_detection": "Clear",
  "face_age_estimation": 24,
  "dark_circles": "Slight",
  "hair_density": 88.0,
  "analytics": {
    "markers": [
      {"title": "[Title in $language]", "message": "[Message in $language]", "top": 90.0, "left": 155.0},
      {"title": "[Title in $language]", "message": "[Message in $language]", "top": 190.0, "left": 210.0}
    ],
    "reports": {
      "aura": { "score": "86%", "items": ["[GrowUp AI insight 1 in $language]", "[GrowUp AI insight 2 in $language]"] },
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

    final exactTokens = response.usageMetadata?.totalTokenCount;
    final estimatedTokens = exactTokens ?? ((prompt.toString().length + rawText.length) / 4).round();
    await _trackUsage('analytics_scan', estimatedTokens);

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

      parseSection(decoded['morning_routine'], 'morning', 'wb_sunny', 'dm');
      parseSection(decoded['noon_routine'],    'noon',    'wb_twilight', 'dn');
      parseSection(decoded['evening_routine'], 'evening', 'wb_iridescent', 'de');
      parseSection(decoded['night_routine'],   'night',   'nights_stay',  'dnt');

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

  // ══ OUTFIT RECOMMENDATIONS ════════════════════════════════════════════════

  static String outfitSystemPrompt(String language) => '''
You are an elite Fashion AI Stylist. Your task is to analyze the user's uploaded photo and generate a complete outfit recommendation.

IMPORTANT RULE 1: First, check if the image actually contains a human person. If the image does NOT contain a human (for example, it is a landscape, an object, an animal, or a blank image), you must set "is_human_detected" to false and provide an "error_message" describing what you see instead. DO NOT generate outfit recommendations for non-human images.
IMPORTANT RULE 2: If a human is detected, set "is_human_detected" to true and generate a highly detailed outfit recommendation.
IMPORTANT RULE 3: You MUST write your entire response exclusively in the $language language.
IMPORTANT RULE 4: For every "description" field in the categories, provide extremely detailed advice including fabric types, color coordination, fit recommendations, and why it suits them. Do not give short answers.

Return ONLY raw JSON. No markdown, no backticks.

{
  "is_human_detected": true,
  "error_message": "[If not human, describe what the image is in $language. If human, leave empty or null]",
  "overall_verdict": "[Detailed paragraph analyzing their skin tone, hair style, body shape, and giving an overall styling recommendation in $language]",
  "color_palette": [
    {"hex": "#000000", "name": "[Color Name in $language]"},
    {"hex": "#FFFFFF", "name": "[Color Name in $language]"},
    {"hex": "#F5F5DC", "name": "[Color Name in $language]"}
  ],
  "categories": [
    {
      "name": "Casual",
      "items": [
        {"type": "Topwear", "description": "[Highly detailed description covering fabric, fit, and style in $language]"},
        {"type": "Bottomwear", "description": "[Highly detailed description covering fabric, fit, and style in $language]"},
        {"type": "Footwear", "description": "[Highly detailed description covering style and color in $language]"},
        {"type": "Accessories", "description": "[Highly detailed description covering style in $language]"}
      ]
    },
    {
      "name": "Formal",
      "items": [
        {"type": "Topwear", "description": "[Highly detailed description covering fabric, fit, and style in $language]"},
        {"type": "Bottomwear", "description": "[Highly detailed description covering fabric, fit, and style in $language]"},
        {"type": "Footwear", "description": "[Highly detailed description covering style and color in $language]"},
        {"type": "Accessories", "description": "[Highly detailed description covering style in $language]"}
      ]
    },
    {
      "name": "Traditional",
      "items": [
        {"type": "Outfit", "description": "[Highly detailed description covering fabric, fit, and style in $language]"},
        {"type": "Footwear", "description": "[Highly detailed description covering style and color in $language]"},
        {"type": "Accessories", "description": "[Highly detailed description covering style in $language]"}
      ]
    }
  ]
}
''';

  static Future<Map<String, dynamic>> generateOutfitRecommendations(String imagePath, {String language = 'English'}) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _apiKey,
        systemInstruction: Content.system(outfitSystemPrompt(language)),
      );

      final prompt = Content.multi([
        TextPart('Analyze my appearance/outfit and give me the best clothing recommendations according to the JSON format.'),
        DataPart('image/webp', imageBytes),
      ]);

      final response = await model.generateContent([prompt]);
      final rawText = response.text ?? '';

      final cleaned = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final exactTokens = response.usageMetadata?.totalTokenCount;
      final estimatedTokens = exactTokens ?? ((prompt.toString().length + rawText.length) / 4).round();
      await _trackUsage('outfit_generate', estimatedTokens);

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GeminiService.generateOutfitRecommendations error: $e');
      return {};
    }
  }

  // ══ HAIRSTYLE RECOMMENDATIONS ════════════════════════════════════════════════

  static String hairStyleSystemPrompt(String language) => '''
You are an elite Celebrity Hair Stylist and Barber. Your task is to analyze the user's uploaded photo, consider their text preferences, and generate a personalized premium hairstyle report.

IMPORTANT RULE 1: First, check if the image actually contains a human face. If the image does NOT contain a human face, you must set "is_human_detected" to false and provide an "error_message".
IMPORTANT RULE 2: If a human face is detected, set "is_human_detected" to true and generate a highly detailed 4-hairstyle report.
IMPORTANT RULE 3: You MUST write your entire response exclusively in the $language language.
IMPORTANT RULE 4: You must rank exactly 4 hairstyles (#1 to #4) and give each a Match Score (%) and a Benefit Tag (e.g., Enhances Jawline, Professional Look, Makes Face Slimmer).

Return ONLY raw JSON. No markdown, no backticks.

{
  "is_human_detected": true,
  "error_message": "",
  "face_shape_analysis": "[Detailed paragraph analyzing their face shape in $language]",
  "symmetry_score": "[e.g. 85%]",
  "attractiveness_score": "[e.g. 90%]",
  "youthfulness_score": "[e.g. 88%]",
  "jawline": "[e.g. Strong/Defined]",
  "forehead": "[e.g. High/Average]",
  "hairline": "[e.g. Straight/Receding]",
  "recommendations": [
    {
      "rank": "#1",
      "style_name": "[Name of the hairstyle in $language]",
      "benefit_tag": "[e.g. Enhances Jawline in $language]",
      "match_score": "98%",
      "description": "[Detailed description covering the cut in $language]",
      "styling_advice": "[Products to use in $language]",
      "maintenance": "[Maintenance schedule in $language]"
    },
    {
      "rank": "#2",
      "style_name": "[Name of the hairstyle in $language]",
      "benefit_tag": "[e.g. Professional Look in $language]",
      "match_score": "92%",
      "description": "[Description in $language]",
      "styling_advice": "[Advice in $language]",
      "maintenance": "[Maintenance in $language]"
    },
    {
      "rank": "#3",
      "style_name": "[Name of the hairstyle in $language]",
      "benefit_tag": "[e.g. Low Maintenance in $language]",
      "match_score": "88%",
      "description": "[Description in $language]",
      "styling_advice": "[Advice in $language]",
      "maintenance": "[Maintenance in $language]"
    },
    {
      "rank": "#4",
      "style_name": "[Name of the hairstyle in $language]",
      "benefit_tag": "[e.g. Edgy & Modern in $language]",
      "match_score": "85%",
      "description": "[Description in $language]",
      "styling_advice": "[Advice in $language]",
      "maintenance": "[Maintenance in $language]"
    }
  ]
}
''';

  static Future<Map<String, dynamic>> generateHairStyleRecommendations(String imagePath, String preferences, {String language = 'English'}) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(hairStyleSystemPrompt(language)),
      );

      final userText = preferences.isNotEmpty 
          ? 'Analyze my face shape and give me the best hairstyle recommendations. My preferences: \$preferences'
          : 'Analyze my face shape and give me the best hairstyle recommendations according to the JSON format.';

      final prompt = Content.multi([
        TextPart(userText),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await model.generateContent([prompt]);
      final rawText = response.text ?? '';

      final cleaned = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final exactTokens = response.usageMetadata?.totalTokenCount;
      final estimatedTokens = exactTokens ?? ((prompt.toString().length + rawText.length) / 4).round();
      await _trackUsage('haircut_text', estimatedTokens);

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GeminiService.generateHairStyleRecommendations error: $e');
      return {};
    }
  }

  // ══ HAIRSTYLE IMAGE GENERATION ═════════════════════════════════════════════

  static Future<String?> generateHairStyleImage(String imagePath, String prompt) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final dio = Dio();
      // Exact implementation as per official Gemini docs for image-to-image editing
      // https://ai.google.dev/gemini-api/docs/imagen
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image:generateContent?key=$_apiKey';

      // Match the official docs structure: flat parts array with text + inlineData
      final response = await dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['IMAGE', 'TEXT'],
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      debugPrint('Gemini image API status: ${response.statusCode}');
      final data = response.data;

      if (data == null) {
        debugPrint('Gemini API returned null data');
        return null;
      }

      if (data['error'] != null) {
        debugPrint('Gemini API Error: ${data['error']}');
        return null;
      }

      if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
        final parts = data['candidates'][0]['content']['parts'] as List;
        debugPrint('Gemini returned ${parts.length} parts');

        // Scan ALL parts — prioritize inlineData image over text
        String? imageBase64;
        String? textResult;

        for (var part in parts) {
          debugPrint('Part keys: ${part.keys.toList()}');
          if (part['inlineData'] != null) {
            imageBase64 = part['inlineData']['data'] as String?;
            debugPrint('Found image! mimeType: ${part['inlineData']['mimeType']}, length: ${imageBase64?.length}');
          } else if (part['text'] != null) {
            final t = part['text'] as String;
            if (t.isNotEmpty) {
              textResult = t;
              debugPrint('Text part (${t.length} chars): ${t.substring(0, t.length.clamp(0, 120))}');
            }
          }
        }

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          // Track image generation (since there's no token count, track as 1 call for tokens)
          await _trackUsage('haircut_image', 1);
          return imageBase64; // Return base64 image string
        }
        if (textResult != null) {
          debugPrint('No image in response. Text only returned.');
          return textResult;
        }
      } else {
        debugPrint('Gemini API no candidates: $data');
      }
      return null;
    } catch (e) {
      debugPrint('GeminiService.generateHairStyleImage error: $e');
      return null;
    }
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
            'You are GrowUp AI, a highly knowledgeable and supportive personal Lookmaxxing, Glow-up, and Aesthetics Coach. '
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
      final estimatedTokens = exactTokens ?? ((newMessage.length + text.length) / 4).round();
      
      await _trackUsage('coach', exactTokens ?? estimatedTokens);
      
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

  // ══ PERSONALIZED TASKS GENERATION ══════════════════════════════════════════

  static String personalizedTasksSystemPrompt(String language) => '''
You are GrowUp AI, an expert Lookmaxxing, Grooming, and Aesthetics Coach.
Your task is to generate a highly personalized daily routine based on the user's age, gender, skin type, goals, and budget.

IMPORTANT RULES:
1. You MUST generate exactly 8 to 10 tasks in total, spread across morning, noon, evening, and night routines.
2. The "desc" (description) MUST be extremely detailed (at least 2-3 sentences), explaining HOW to do the task and WHY it helps achieve their specific goals.
3. You MUST write ALL text exclusively in the $language language.
4. Return ONLY raw JSON. No markdown, no backticks.

{
  "morning_routine": [
    {"title": "[Routine title in $language] 💧", "desc": "[Highly detailed description in $language]"}
  ],
  "noon_routine": [
    {"title": "[Routine title in $language] ☀️", "desc": "[Highly detailed description in $language]"}
  ],
  "evening_routine": [
    {"title": "[Routine title in $language] 🌇", "desc": "[Highly detailed description in $language]"}
  ],
  "night_routine": [
    {"title": "[Routine title in $language] 🌌", "desc": "[Highly detailed description in $language]"}
  ]
}
''';

  static Future<Map<String, dynamic>> generatePersonalizedTasks({
    required int age,
    required String gender,
    required String skinType,
    required List<String> goals,
    required String budget,
    required String language,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _apiKey,
        systemInstruction: Content.system(personalizedTasksSystemPrompt(language)),
      );

      final promptStr = 'Please generate my personalized daily routine. '
          'My profile: Age: $age, Gender: $gender, Skin Type: $skinType, Budget: $budget, Goals: ${goals.join(", ")}.';
      final prompt = Content.text(promptStr);

      final response = await model.generateContent([prompt]);
      final rawText = response.text ?? '';

      final cleaned = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final exactTokens = response.usageMetadata?.totalTokenCount;
      final estimatedTokens = exactTokens ?? ((promptStr.length + rawText.length) / 4).round();
      await _trackUsage('routine_generate', estimatedTokens);

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GeminiService.generatePersonalizedTasks error: $e');
      return {};
    }
  }

  // ══ TEASER INSIGHT GENERATION ══════════════════════════════════════════════

  static String teaserSystemPrompt(String language) => '''
You are GrowUp AI, an expert Lookmaxxing, Grooming, and Psychological Profiler.
The user has just completed a facial scan but hit a paywall before seeing their full report.
Your task is to generate a SHORT, engaging, and highly psychological teaser paragraph (3-4 sentences max).

IMPORTANT RULES:
1. Briefly hint at their potential areas of improvement based on their goals or aura score (e.g., skin, jawline, symmetry) and mention an estimated timeframe to fix them (e.g., "With 30-45 days of consistent effort...").
2. You MUST include a psychological hook stating that money is not a big deal, but how people look at you and perceive you matters the most in life.
3. Encourage them to unlock PRO to get their fully personalized blueprint.
4. You MUST write your entire response exclusively in the $language language.
5. Return ONLY the plain text paragraph. Do not use quotes, markdown, or JSON.
''';

  static Future<String> generateTeaserInsight({
    required double auraScore,
    required List<String> goals,
    required String language,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _apiKey,
        systemInstruction: Content.system(teaserSystemPrompt(language)),
      );

      final promptStr = 'My Aura Score is ${auraScore.toStringAsFixed(1)} and my goals are: ${goals.join(", ")}. Please generate the psychological teaser.';
      final prompt = Content.text(promptStr);

      final response = await model.generateContent([prompt]);
      final rawText = response.text?.trim() ?? '';

      final exactTokens = response.usageMetadata?.totalTokenCount;
      final estimatedTokens = exactTokens ?? ((promptStr.length + rawText.length) / 4).round();
      await _trackUsage('teaser_generate', estimatedTokens);

      return rawText;
    } catch (e) {
      debugPrint('GeminiService.generateTeaserInsight error: $e');
      return 'Unlock PRO to reveal your full potential. Money is a secondary concern compared to how the world perceives you. Discover your tailored blueprint today.';
    }
  }
}
