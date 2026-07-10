import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final raw = await FirestoreService().getChatSessions(user.uid);
    setState(() {
      _sessions = raw;
      _isLoading = false;
    });
  }

  Future<void> _deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete Chat', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this conversation? This cannot be undone.', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().deleteChatSession(user.uid, id);
      }
      await _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header back button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'CHAT HISTORY LOGS',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Text(
                  'PAST LOOKMAXXING DISCUSSIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Sessions List
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _sessions.isEmpty
                          ? Center(
                              child: Text(
                                'No chat history yet.',
                                style: GoogleFonts.outfit(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _sessions.length,
                              itemBuilder: (context, idx) {
                                final s = _sessions[idx];
                                final title = s['title'] as String;
                                DateTime dateRaw;
                                if (s['updated_at'] is String) {
                                  dateRaw = DateTime.parse(s['updated_at'] as String);
                                } else {
                                  dateRaw = (s['updated_at'] as Timestamp).toDate();
                                }
                                final dateStr = DateFormat('d MMM yyyy, h:mm a').format(dateRaw);
                                final category = 'General';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop(s['id']); // Return session ID
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(8),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Row(
                                        children: [
                                          // Category Icon
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(category).withAlpha(30),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(category),
                                              color: _getCategoryColor(category),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Session details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _getCategoryColor(category).withAlpha(40),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        category.toUpperCase(),
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: _getCategoryColor(category),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      dateStr,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 10,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  title,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tap to continue chatting...',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Delete Button
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30),
                                            onPressed: () => _deleteSession(s['id'] as String),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Mewing':
        return Icons.tune_rounded;
      case 'Skin':
        return Icons.face_rounded;
      case 'Posture':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Mewing':
        return AppTheme.primary;
      case 'Skin':
        return AppTheme.secondary;
      case 'Posture':
        return AppTheme.success;
      default:
        return Colors.orange;
    }
  }
}
