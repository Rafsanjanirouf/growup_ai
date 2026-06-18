import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/language_picker_sheet.dart';
import 'chat_history_screen.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AICoachScreen extends StatefulWidget {
  final bool isTab;
  final String? sessionId; // Added sessionId for continuing previous chats
  const AICoachScreen({super.key, this.isTab = false, this.sessionId});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String? _currentSessionId;

  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Bengali', 'Hindi'];
  
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingAudio = false;
  bool _autoVoiceOn = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initData();
  }

  Future<void> _initData() async {
    // 1. Fetch saved language and voice settings from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirestoreService().getUserData(user.uid);
      if (userData != null) {
        if (userData.containsKey('coach_language')) {
          final savedLang = userData['coach_language'] as String;
          if (_languages.contains(savedLang) && mounted) {
            setState(() => _selectedLanguage = savedLang);
          }
        }
        if (userData.containsKey('coach_auto_voice') && mounted) {
          setState(() => _autoVoiceOn = userData['coach_auto_voice'] as bool);
        }
      }
    }

    // 2. Load latest session if none provided
    if (widget.sessionId != null) {
      _currentSessionId = widget.sessionId;
      await _loadMessages();
    } else {
      final sessions = await LocalDbService().getChatSessions();
      if (sessions.isNotEmpty) {
        _currentSessionId = sessions.first['id'] as String;
        await _loadMessages();
      } else {
        _startNewChat();
      }
    }
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlayingAudio = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingAudio = false);
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  void _stopTts() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  void _listen() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission required for Voice Input.', style: GoogleFonts.outfit()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) => setState(() {
            _messageController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop(); // Stop any currently playing audio

    // Clean text for natural speech (remove markdown symbols and emojis)
    String cleanText = text.replaceAll(RegExp(r'\*|\#|_|`'), '');
    cleanText = cleanText.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '');
    cleanText = cleanText.trim();

    if (_selectedLanguage == 'Bengali') {
      await _flutterTts.setLanguage("bn-IN"); 
    } else if (_selectedLanguage == 'Hindi') {
      await _flutterTts.setLanguage("hi-IN");
    } else {
      await _flutterTts.setLanguage("en-US");
    }
    await _flutterTts.speak(cleanText);
  }

  void _startNewChat() async {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _messages.add(
        ChatMessage(
          id: const Uuid().v4(),
          text: "Salutations, lookmaxxer! 🤖\n\nI am Aura AI, your personal Lookmaxxing & Glow-up Coach. Ask me anything about Mewing techniques, skin textures, postures, or masseter muscle conditioning!",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final scans = await LocalDbService().getAllScans(user.uid);
        if (scans.isNotEmpty) {
          final latest = scans.first;
          final auraScore = (latest['aura_score'] as num).toDouble().toStringAsFixed(1);
          final skinScore = (latest['skin_score'] as num).toDouble().toStringAsFixed(1);
          final jawlineScore = (latest['jawline_score'] as num).toDouble().toStringAsFixed(1);
          final rating = latest['rating'] as String? ?? 'Developing';

          final reportText = "Here is a quick look at your latest analysis:\n\n"
              "**Aura Score**: $auraScore ($rating)\n"
              "**Skin Score**: $skinScore\n"
              "**Jawline Score**: $jawlineScore\n\n"
              "Would you like me to analyze this further or give you personalized tips to improve these scores?";

          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  id: const Uuid().v4(),
                  text: reportText,
                  isUser: false,
                  timestamp: DateTime.now().add(const Duration(seconds: 1)),
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching latest scan for chat: $e");
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AURA AI SETTINGS',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // History
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
                      ),
                      title: Text('Chat History', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(context); // Close sheet
                        final selectedSessionId = await Navigator.of(this.context).push(
                          MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
                        );
                        if (selectedSessionId != null && selectedSessionId is String) {
                          setState(() {
                            _currentSessionId = selectedSessionId;
                            _messages.clear();
                          });
                          await _loadMessages();
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    
                    // Auto Voice
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.primary,
                      title: Text('Auto Voice Playback', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                      subtitle: Text('AURA AI will read replies aloud', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volume_up_rounded, color: Colors.orangeAccent, size: 20),
                      ),
                      value: _autoVoiceOn,
                      onChanged: (bool val) {
                        setModalState(() => _autoVoiceOn = val);
                        setState(() => _autoVoiceOn = val);
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          FirestoreService().updateUser(user.uid, {'coach_auto_voice': val});
                        }
                        if (!val) _stopTts();
                      },
                    ),
                    const Divider(color: Colors.white10),

                    // Language
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language_rounded, color: Colors.greenAccent, size: 20),
                      ),
                      title: Text('Language', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedLanguage,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        ],
                      ),
                      onTap: () async {
                        final chosen = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isDismissible: true,
                          enableDrag: true,
                          isScrollControlled: true,
                          builder: (ctx) => LanguagePickerSheet(
                            selectedLanguage: _selectedLanguage,
                          ),
                        );
                        if (chosen != null && mounted) {
                          setModalState(() => _selectedLanguage = chosen);
                          setState(() => _selectedLanguage = chosen);
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            FirestoreService().updateUser(user.uid, {'coach_language': chosen});
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadMessages() async {
    if (_currentSessionId != null) {
      final raw = await LocalDbService().getChatMessages(_currentSessionId!);
      if (raw.isNotEmpty) {
        setState(() {
          _messages.addAll(raw.map((e) => ChatMessage(
                id: e['id'] as String,
                text: e['text'] as String,
                isUser: (e['is_user'] as int) == 1,
                timestamp: DateTime.parse(e['timestamp'] as String),
              )));
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveMessageLocal(ChatMessage m) async {
    if (_currentSessionId == null) return;
    await LocalDbService().insertChatMessage(
      id: m.id,
      sessionId: _currentSessionId!,
      text: m.text,
      isUser: m.isUser,
      timestamp: m.timestamp,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_isTyping) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check Token Limit before sending
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final usedTokens = await FirestoreService().getDailyTokenUsage(userId: user.uid, dateKey: dateKey);
      final limit = await FirestoreService().getDailyTokenLimit();
      
      if (usedTokens >= limit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily AI limit reached! ($limit tokens). Please try again tomorrow.', style: GoogleFonts.outfit()),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    _messageController.clear();
    
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    // If it's a new session, create it first
    if (_currentSessionId == null) {
      _currentSessionId = const Uuid().v4();
      final words = text.split(' ');
      final title = words.take(4).join(' ') + (words.length > 4 ? '...' : '');
      await LocalDbService().createChatSession(
        id: _currentSessionId!,
        title: title,
        updatedAt: DateTime.now(),
      );
      // Save the default welcome message that was already in the list
      if (_messages.isNotEmpty && !_messages.first.isUser) {
        await _saveMessageLocal(_messages.first);
      }
    } else {
      await LocalDbService().updateChatSessionDate(_currentSessionId!, DateTime.now());
    }

    await _saveMessageLocal(userMsg);

    // Remove early tracker, we track after getting tokens
    
    // Trigger AI Coach response
    try {
      final historyPayload = _messages.take(_messages.length - 1).map((m) => {
        'isUser': m.isUser,
        'text': m.text,
      }).toList();
      
      final result = await GeminiService.chatWithCoach(
        history: historyPayload,
        newMessage: text,
        language: _selectedLanguage,
      );
      
      final responseText = result['text'] as String;
      final tokensUsed = result['tokens'] as int;

      // Track token usage in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        FirestoreService().trackChatUsage(userId: user.uid, dateKey: dateKey, tokensUsed: tokensUsed);
      }

      if (!mounted) return;

      final aiMsg = ChatMessage(
        id: const Uuid().v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMsg);
      });
      _scrollToBottom();
      await _saveMessageLocal(aiMsg);
      
      // Auto-play TTS if enabled
      if (_autoVoiceOn) {
        await _speak(responseText);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
      }
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
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Coach Info bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    if (!widget.isTab)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    // Coach Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.secondary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondary.withAlpha(50),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: AppTheme.surface,
                        child: Text('🤖', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AURA AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Online Glow Coach',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: AppTheme.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // New Chat Button
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                      tooltip: 'New Chat',
                      onPressed: _startNewChat,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white),
                      tooltip: 'Settings',
                      onPressed: _showSettingsSheet,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Chat Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, idx) {
                    final m = _messages[idx];
                    return _buildMessageBubble(m);
                  },
                ),
              ),

              // Typing loader
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'AURA AI is compiling reply...',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Suggestions chips
              _buildSuggestionsChips(),

              // Bottom Input Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask about Mewing, Acne, Sunscreens...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                          filled: true,
                          fillColor: Colors.black38,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _listen,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.redAccent : Colors.white.withAlpha(20),
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
              
              // Audio Player Overlay
              if (_isPlayingAudio)
                Positioned(
                  bottom: 85, // Above Input Section
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withAlpha(240),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primary.withAlpha(100), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AURA AI Speaking...',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Tap Stop to pause playback',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _stopTts,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stop_rounded, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Stop',
                                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: m.isUser ? AppTheme.primary.withAlpha(50) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(m.isUser ? 20 : 4),
            bottomRight: Radius.circular(m.isUser ? 4 : 20),
          ),
          border: Border.all(
            color: m.isUser ? AppTheme.primary.withAlpha(100) : Colors.white10,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParsedText(m.text, m.isUser),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: m.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message copied to clipboard', style: GoogleFonts.outfit()),
                        backgroundColor: AppTheme.success,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _speak(m.text),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedText(String text, bool isUser) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.outfit(
          color: isUser ? Colors.white : AppTheme.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          height: 1.4,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildSuggestionsChips() {
    final suggestions = ['Analyze my latest report 📊', 'How to Mew? 📐', 'Acne Treatment? 🧼', 'Chewing Gum? 🦷', 'Posture Tip? 🧍'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: suggestions.length,
        itemBuilder: (context, idx) {
          final s = suggestions[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: Colors.white.withAlpha(12),
              side: const BorderSide(color: Colors.white10),
              label: Text(
                s,
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _messageController.text = s.substring(0, s.length - 2).trim(); // Strip emoji
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }
}

