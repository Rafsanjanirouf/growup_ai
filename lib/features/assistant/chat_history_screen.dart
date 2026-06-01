import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/providers/chat_history_provider.dart';
import '../../core/models/chat_session.dart';
import '../../core/providers/assistant_provider.dart';

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(chatHistoryProvider);
    final groupedSessions = _groupSessions(historyState.sessions);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'CHAT HISTORY',
        showBackButton: true,
      ),
      body: historyState.sessions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: groupedSessions.keys.length,
              itemBuilder: (context, index) {
                final category = groupedSessions.keys.elementAt(index);
                final sessions = groupedSessions[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16, top: 8),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    ...sessions.map((session) => _buildSessionCard(context, ref, session)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }

  Map<String, List<ChatSession>> _groupSessions(List<ChatSession> sessions) {
    final Map<String, List<ChatSession>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var session in sessions) {
      final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      String category;
      
      if (sessionDate == today) {
        category = "Today";
      } else if (sessionDate == yesterday) {
        category = "Yesterday";
      } else {
        category = DateFormat('MMMM yyyy').format(sessionDate);
      }

      if (!groups.containsKey(category)) {
        groups[category] = [];
      }
      groups[category]!.add(session);
    }
    return groups;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, WidgetRef ref, ChatSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          // Load session back into active assistant and pop
          ref.read(assistantProvider.notifier).loadSession(session.messages);
          Navigator.pop(context);
        },
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
        ),
        title: Text(
          session.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            session.lastMessagePreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('HH:mm').format(session.startTime),
              style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${session.messages.length} msgs',
              style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
