import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AssistantState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final int dailyMessageCount;

  AssistantState({
    required this.messages,
    required this.isLoading,
    required this.dailyMessageCount,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    int? dailyMessageCount,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      dailyMessageCount: dailyMessageCount ?? this.dailyMessageCount,
    );
  }
}

class AssistantNotifier extends StateNotifier<AssistantState> {
  final GeminiService _aiService = GeminiService();

  AssistantNotifier() : super(AssistantState(
    messages: [
      ChatMessage(
        text: 'Welcome back, Alpha. How can I assist your transformation today?',
        isUser: false,
        timestamp: DateTime.now(),
      )
    ],
    isLoading: false,
    dailyMessageCount: 0,
  ));

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      dailyMessageCount: state.dailyMessageCount + 1,
    );

    final aiResponse = await _aiService.getResponse(text);
    
    final botMsg = ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now());
    
    state = state.copyWith(
      messages: [...state.messages, botMsg],
      isLoading: false,
    );
  }
}

final assistantProvider = StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  return AssistantNotifier();
});
