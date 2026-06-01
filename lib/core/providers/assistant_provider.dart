import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class AssistantState {
  final List<ChatMessage> messages;
  final bool isTyping;

  AssistantState({
    this.messages = const [],
    this.isTyping = false,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class AssistantNotifier extends StateNotifier<AssistantState> {
  AssistantNotifier() : super(AssistantState(messages: [
    ChatMessage(
      id: const Uuid().v4(),
      text: "How can I help you grow today? I'm currently analyzing your latest biometric trends.",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ),
  ]));

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    // Simulate AI thinking and response
    _simulateAiResponse(text);
  }

  void _simulateAiResponse(String userText) {
    Timer(const Duration(seconds: 2), () {
      String responseText = "I see. I'm adding that to your growth roadmap. Is there anything specific from your last scan you'd like to discuss?";
      
      final lowerText = userText.toLowerCase();
      if (lowerText.contains('skin') || lowerText.contains('texture')) {
        responseText = "Based on your recent high-fidelity scan, your skin texture shows a 12% improvement in hydration. I recommend continuing the Emerald Glow routine.";
      } else if (lowerText.contains('routine') || lowerText.contains('help')) {
        responseText = "I've updated your daily missions. You have 3 new tasks to optimize your facial posture today. Ready to start?";
      }

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        text: responseText,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        type: (lowerText.contains('skin') || lowerText.contains('texture')) 
            ? MessageType.advancedRecommendation 
            : MessageType.text,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isTyping: false,
      );
    });
  }

  void loadSession(List<ChatMessage> messages) {
    state = state.copyWith(
      messages: messages,
      isTyping: false,
    );
  }
}

final assistantProvider = StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  return AssistantNotifier();
});
