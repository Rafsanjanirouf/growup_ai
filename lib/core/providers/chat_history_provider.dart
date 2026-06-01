import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class ChatHistoryState {
  final List<ChatSession> sessions;
  final bool isLoading;

  ChatHistoryState({
    this.sessions = const [],
    this.isLoading = false,
  });

  ChatHistoryState copyWith({
    List<ChatSession>? sessions,
    bool? isLoading,
  }) {
    return ChatHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatHistoryNotifier extends StateNotifier<ChatHistoryState> {
  ChatHistoryNotifier() : super(ChatHistoryState()) {
    _loadMockHistory();
  }

  void _loadMockHistory() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 5));

    final mockSessions = [
      ChatSession(
        id: const Uuid().v4(),
        title: "Skin Hydration Analysis",
        startTime: yesterday,
        lastMessagePreview: "Your skin texture has improved by 12%...",
        messages: [
          ChatMessage(id: '1', text: "How is my skin?", sender: MessageSender.user, timestamp: yesterday),
          ChatMessage(id: '2', text: "Analyzing... Your skin texture has improved by 12%.", sender: MessageSender.ai, timestamp: yesterday),
        ],
      ),
      ChatSession(
        id: const Uuid().v4(),
        title: "Morning Facial Posture",
        startTime: lastWeek,
        lastMessagePreview: "I've updated your posture roadmap.",
        messages: [
          ChatMessage(id: '3', text: "Help with jaw posture", sender: MessageSender.user, timestamp: lastWeek),
          ChatMessage(id: '4', text: "I've updated your posture roadmap.", sender: MessageSender.ai, timestamp: lastWeek),
        ],
      ),
    ];

    state = state.copyWith(sessions: mockSessions);
  }

  void addSession(ChatSession session) {
    state = state.copyWith(sessions: [session, ...state.sessions]);
  }
}

final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, ChatHistoryState>((ref) {
  return ChatHistoryNotifier();
});
