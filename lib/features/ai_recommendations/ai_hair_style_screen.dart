import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/language_picker_sheet.dart';
import 'hair_style_history_screen.dart';
import 'hair_style_image_fullscreen.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AiHairStyleScreen extends ConsumerStatefulWidget {
  const AiHairStyleScreen({super.key});

  @override
  ConsumerState<AiHairStyleScreen> createState() => _AiHairStyleScreenState();
}

class _AiHairStyleScreenState extends ConsumerState<AiHairStyleScreen> {
  bool _isGenerating = false;
  File? _selectedImage;
  final TextEditingController _preferencesController = TextEditingController();
  
  int _selectedMode = 0; // 0 for Text Mode, 1 for Image Mode
  Map<String, dynamic>? _generatedTextResult;
  String? _generatedImageResult;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _generatedTextResult = null;
          _generatedImageResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFDCC091)),
              title: Text('Take a Photo', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFCC9974)),
              title: Text('Choose from Gallery', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateHairstyles() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image first', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_selectedMode == 0) {
        // Text Mode Limit
        final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final used = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
        final limit = await FirestoreService().getDailyImageToTextLimit();
        if (used >= limit) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Daily AI limit reached! ($limit generations). Please try again tomorrow.', style: GoogleFonts.outfit()),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
          return;
        }
      } else {
        // Image Mode Limit
        final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
        final used = await FirestoreService().getMonthlyImageGenerationUsage(userId: user.uid, monthKey: monthKey);
        final limit = await FirestoreService().getMonthlyImageGenerationLimit();
        if (used >= limit) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Monthly Premium AI limit reached! ($limit generations).', style: GoogleFonts.outfit()),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedTextResult = null;
      _generatedImageResult = null;
    });

    try {
      if (_selectedMode == 0) {
        // Text Mode
        final language = ref.read(userStateProvider).coachLanguage;
        final result = await GeminiService.generateHairStyleRecommendations(
          _selectedImage!.path,
          _preferencesController.text,
          language: language,
        );

        if (result.isEmpty) {
          setState(() {
            _errorMessage = 'Failed to generate recommendations. Please try again.';
            _isGenerating = false;
          });
          return;
        }

        final isHuman = result['is_human_detected'] as bool? ?? true;
        if (!isHuman) {
          setState(() {
            _errorMessage = result['error_message'] ?? 'No human face detected.';
            _isGenerating = false;
          });
          return;
        }

        await _saveToDb(fullData: result);

        if (user != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          FirestoreService().trackImageToTextUsage(userId: user.uid, dateKey: dateKey);
        }

        setState(() {
          _generatedTextResult = result;
          _isGenerating = false;
        });
      } else {
        // Image Mode
        final prompt = '''
Create a premium AI Hairstyle Match Report using the uploaded photo.

Analyze the person's face shape, facial symmetry, jawline, forehead, hairline, age appearance, and overall attractiveness.

Generate ONE luxury report image in a clean 2x2 grid showing the same person with the 4 best matching hairstyles ranked #1-#4.

Rules:
• Keep the person's identity unchanged.
• Do NOT alter face shape, jawline, eyes, nose, lips, skin tone, or facial proportions.
• Only change the hairstyle.
• Use realistic, modern, high-quality hairstyles.
• Rank styles by compatibility score.

Top Analysis Section:
• Face Shape
• Jawline
• Forehead
• Hairline
• Symmetry Score
• Attractiveness Score
• Youthfulness Score

Each Hairstyle Card:
• Large portrait
• Rank (#1-#4)
• Hairstyle Name
• Benefit Tag (e.g. Enhances Jawline, Professional Look, Makes Face Slimmer)
• Match Score (%)

Design Style:
• Premium AI beauty consultation report
• Luxury grooming app UI
• Clean white cards
• Soft shadows
• Professional typography
• Ultra realistic
• 4K quality

Color System:
Background: #F3F4F5
Navy: #162A42
Dark Navy: #0F2238
Gold: #DCC091
Dark Gold: #CC9974
Border: #D8D2C7
White Cards: #FFFFFF

Branding:
Place "GrowUp-AI" centered at the bottom in a modern premium AI-style logo.

Output must look like a professional report from a luxury AI glow-up and hairstyle recommendation app.
''';
        final result = await GeminiService.generateHairStyleImage(
          _selectedImage!.path,
          prompt,
        );

        if (result == null || result.isEmpty) {
          setState(() {
            _errorMessage = 'Image generation failed — model returned no image. Check terminal logs for details.';
            _isGenerating = false;
          });
          return;
        }

        // If it's clearly just plain text (not base64), show it differently
        bool looksLikeBase64 = result.length > 200 && !result.contains(' ') && !result.contains('\n');
        if (!looksLikeBase64 && !result.startsWith('http')) {
          // The model returned text instead of an image
          debugPrint('WARNING: Model returned text instead of image: ${result.substring(0, result.length.clamp(0, 200))}');
        }

        await _saveToDb(fullData: {'image_result': result, 'mode': 'image'});

        if (user != null) {
          final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
          FirestoreService().trackImageGenerationUsage(userId: user.uid, monthKey: monthKey);
        }

        setState(() {
          _generatedImageResult = result;
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveToDb({required Map<String, dynamic> fullData}) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    final scanId = const Uuid().v4();

    await LocalDbService().insertHairStyleScan(
      id: scanId,
      userId: userId,
      date: DateTime.now(),
      imagePath: _selectedImage!.path,
      fullData: fullData,
    );

    // Trigger background sync to upload to Firestore
    SyncService().syncPendingScans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Text(
          'AI Hairstyle',
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: Colors.white.withAlpha(100),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () async {
                final currentLang = ref.read(userStateProvider).coachLanguage;
                final chosen = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isDismissible: true,
                  enableDrag: true,
                  isScrollControlled: true,
                  builder: (ctx) => LanguagePickerSheet(
                    selectedLanguage: currentLang,
                  ),
                );
                if (chosen != null) {
                  ref.read(userStateProvider.notifier).updateLanguage(chosen);
                }
              },
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ref.watch(userStateProvider).coachLanguage,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HairStyleHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModeSelector(),
                const SizedBox(height: 24),
                _buildUploadSection(),
                const SizedBox(height: 24),
                _buildStylePreferences(),
                const SizedBox(height: 32),
                _buildGenerateButton(),
                const SizedBox(height: 32),
                if (_isGenerating)
                  _buildGeneratingState()
                else if (_errorMessage != null)
                  _buildErrorState()
                else if (_generatedTextResult != null)
                  _buildPremiumReportView()
                else if (_generatedImageResult != null)
                  _buildImageReportView()
                else
                  _buildResultsPlaceholder(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingState() {
    final steps = _selectedMode == 1
        ? [
            '🔍  Analyzing face structure...',
            '✂️  Matching hairstyle profiles...',
            '🎨  Rendering hairstyle cards...',
            '✨  Applying premium finish...',
          ]
        : [
            '🔍  Detecting face shape...',
            '📊  Scoring facial features...',
            '💇  Finding top 4 hairstyles...',
            '📋  Building your report...',
          ];

    return GlassContainer(
      glowColor: AppTheme.primary,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 32),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _selectedMode == 1 ? 'Generating Image...' : 'Analyzing Features...',
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMode == 1
                ? 'Applying premium styles to your photo...'
                : 'Scoring features & finding best matches...',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    step,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMode = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedMode == 0 ? AppTheme.gradientAccent : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedMode == 0
                      ? [BoxShadow(color: AppTheme.primary.withAlpha(100), blurRadius: 12)]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.text_snippet_rounded,
                        size: 18,
                        color: _selectedMode == 0 ? Colors.black : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Text Report',
                        style: GoogleFonts.outfit(
                          fontWeight: _selectedMode == 0 ? FontWeight.w900 : FontWeight.w500,
                          color: _selectedMode == 0 ? Colors.black : Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMode = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedMode == 1 ? AppTheme.gradientAccent : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedMode == 1
                      ? [BoxShadow(color: AppTheme.primary.withAlpha(100), blurRadius: 12)]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 18,
                        color: _selectedMode == 1 ? Colors.black : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Image',
                        style: GoogleFonts.outfit(
                          fontWeight: _selectedMode == 1 ? FontWeight.w900 : FontWeight.w500,
                          color: _selectedMode == 1 ? Colors.black : Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGlow.withAlpha(20),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to Upload Face Photo',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use a clear, front-facing photo',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStylePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hair Preferences (Optional)',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _preferencesController,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. textured fringe, buzz cut, messy middle part',
            hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppTheme.glassBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    final isEnabled = !_isGenerating && _selectedImage != null;

    return GestureDetector(
      onTap: isEnabled ? _generateHairstyles : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isEnabled ? AppTheme.gradientAccent : null,
          color: isEnabled ? null : AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? Colors.transparent : AppTheme.glassBorder,
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: _isGenerating
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'GENERATE HAIRSTYLE',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isEnabled ? Colors.black : Colors.white54,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumReportView() {
    final faceAnalysis = _generatedTextResult?['face_shape_analysis'] ?? '';
    final symScore = _generatedTextResult?['symmetry_score'] ?? '-';
    final attractScore = _generatedTextResult?['attractiveness_score'] ?? '-';
    final youthScore = _generatedTextResult?['youthfulness_score'] ?? '-';
    
    final jawline = _generatedTextResult?['jawline'] ?? '-';
    final forehead = _generatedTextResult?['forehead'] ?? '-';
    final hairline = _generatedTextResult?['hairline'] ?? '-';

    final recommendations = _generatedTextResult?['recommendations'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'GROWUP-AI',
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'PREMIUM AI HAIRSTYLE MATCH REPORT',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // TOP ANALYSIS SECTION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Facial Analysis',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                faceAnalysis,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              Divider(height: 32, color: AppTheme.glassBorder),
              _buildAnalysisRow('Jawline', jawline),
              _buildAnalysisRow('Forehead', forehead),
              _buildAnalysisRow('Hairline', hairline),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreCircle('Symmetry', symScore),
                  _buildScoreCircle('Attraction', attractScore),
                  _buildScoreCircle('Youth', youthScore),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Top 4 Matches',
          style: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        ...recommendations.map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(String label, String score) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary, width: 2),
            color: AppTheme.primary.withAlpha(20),
          ),
          child: Center(
            child: Text(
              score,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(dynamic rec) {
    final rank = rec['rank'] ?? '';
    final name = rec['style_name'] ?? 'Hairstyle';
    final tag = rec['benefit_tag'] ?? '';
    final matchScore = rec['match_score'] ?? '';
    final desc = rec['description'] ?? '';

    return GlassContainer(
      glowColor: AppTheme.primary,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Text(
                      rank,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                desc,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.clean_hands, 'Styling:', rec['styling_advice'] ?? ''),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.calendar_month, 'Maintenance:', rec['maintenance'] ?? ''),
            ],
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'Match',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  matchScore,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.secondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '\$label ',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageReportView() {
    final resultStr = _generatedImageResult!.trim();

    // Check if it's a valid base64 image
    bool isImage = false;
    Uint8List? imageBytes;
    try {
      final decoded = base64Decode(resultStr);
      if (decoded.length > 500 && !resultStr.contains(' ') && !resultStr.contains('\n')) {
        isImage = true;
        imageBytes = decoded;
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Text(
            'GROWUP-AI',
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'PREMIUM AI HAIRSTYLE MATCH REPORT',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (isImage && imageBytes != null) ...
          [
            // Image Card — tappable → full screen
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HairStyleImageFullscreen(
                      imageBase64: resultStr,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGlow.withAlpha(30),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    // Gradient overlay at bottom
                    Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    // Tap to expand hint
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Tap to open full screen',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.fullscreen_rounded,
                    label: 'Full Screen',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HairStyleImageFullscreen(
                            imageBase64: resultStr,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.download_rounded,
                    label: 'Save',
                    color: AppTheme.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HairStyleImageFullscreen(
                            imageBase64: resultStr,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ]
        else ...
          [
            // Text fallback (model returned text, not image)
            GlassContainer(
              glowColor: AppTheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI Hairstyle Analysis',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resultStr,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1.5),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, size: 48, color: Colors.white24),
                const SizedBox(height: 12),
                Text(
                  'Your Premium Report\nwill appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
