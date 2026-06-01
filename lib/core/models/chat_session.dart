import '../models/chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime startTime;
  final List<ChatMessage> messages;
  final String lastMessagePreview;

  ChatSession({
    required this.id,
    required this.title,
    required this.startTime,
    required this.messages,
    required this.lastMessagePreview,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    List<ChatMessage>? messages,
    String? lastMessagePreview,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      messages: messages ?? this.messages,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
