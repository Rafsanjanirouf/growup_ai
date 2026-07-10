import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/gemini_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'outfit_history_screen.dart';
import '../../core/widgets/language_picker_sheet.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/usage_limit_progress_bar.dart';

import '../../core/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AiOutfitScreen extends ConsumerStatefulWidget {
  const AiOutfitScreen({super.key});

  @override
  ConsumerState<AiOutfitScreen> createState() => _AiOutfitScreenState();
}

class _AiOutfitScreenState extends ConsumerState<AiOutfitScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  
  Map<String, dynamic>? _outfitData;
  int _selectedCategoryIndex = 0;

  int _usedOutfit = 0;
  int _outfitLimit = 0;

  @override
  void initState() {
    super.initState();
    _fetchLimits();
  }

  Future<void> _fetchLimits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final used = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
      final limit = await FirestoreService().getDailyImageToTextLimit();
      if (mounted) {
        setState(() {
          _usedOutfit = used;
          _outfitLimit = limit;
        });
      }
    }
  }

  IconData _getIconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('top') || lower.contains('shirt') || lower.contains('jacket')) return Icons.checkroom_rounded;
    if (lower.contains('bottom') || lower.contains('pant') || lower.contains('jeans') || lower.contains('trouser')) return Icons.airline_seat_legroom_normal_rounded;
    if (lower.contains('foot') || lower.contains('shoe') || lower.contains('sneaker')) return Icons.roller_skating_rounded;
    if (lower.contains('access') || lower.contains('watch') || lower.contains('glass')) return Icons.watch_rounded;
    if (lower.contains('outfit')) return Icons.accessibility_new_rounded;
    return Icons.checkroom_rounded;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _outfitData = null;
        _selectedCategoryIndex = 0;
      });
    }
  }

  Future<void> _analyzeOutfit() async {
    if (_selectedImage == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final used = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
      final limit = await FirestoreService().getDailyImageToTextLimit();
      
      if (used >= limit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily AI limit reached! ($limit generations). Please try again tomorrow.', style: GoogleFonts.outfit()),
              backgroundColor: AppTheme.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _outfitData = null;
      _selectedCategoryIndex = 0;
    });

    final language = ref.read(userStateProvider).coachLanguage;
    final data = await GeminiService.generateOutfitRecommendations(
      _selectedImage!.path,
      language: language,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (data.isNotEmpty) {
      if (data['is_human_detected'] == false) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              'Invalid Image',
              style: GoogleFonts.outfit(color: AppTheme.danger, fontWeight: FontWeight.bold),
            ),
            content: Text(
              data['error_message'] ?? 'Please upload a photo of a person.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK', style: GoogleFonts.outfit(color: AppTheme.primary)),
              ),
            ],
          ),
        );
      } else if (data.containsKey('categories')) {
        setState(() {
          _outfitData = data;
        });

        // Track Usage
        if (user != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          FirestoreService().trackImageToTextUsage(userId: user.uid, dateKey: dateKey);
        }

        // Save to Firestore
        if (user != null) {
          final scanId = DateTime.now().millisecondsSinceEpoch.toString();
          final imageUrl = await FirestoreService().uploadImage(_selectedImage!.path, user.uid, scanId);
          await FirestoreService().saveOutfitRecord(
            id: scanId,
            userId: user.uid,
            date: DateTime.now(),
            imageUrl: imageUrl,
            fullData: data,
          );

          // Update limits UI after successful scan
          final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final updatedUsed = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
          if (mounted) {
            setState(() {
              _usedOutfit = updatedUsed;
            });
          }
        }
      }
    } else {
      // Fallback or error handling could go here.
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFFFFFFFF);
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
          'AI Stylist',
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
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OutfitHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UsageLimitProgressBar(
                  title: 'Daily AI Stylist',
                  used: _usedOutfit,
                  limit: _outfitLimit,
                  icon: Icons.checkroom_rounded,
                ),
                // Image Input Area
                GestureDetector(
                  onTap: _pickImage,
                  child: GlassContainer(
                    glowColor: AppTheme.primary,
                    padding: EdgeInsets.zero,
                    child: Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                              // Gradient Overlay for button visibility
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black.withAlpha(150)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white.withAlpha(80)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Retake Photo',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primary.withAlpha(50), width: 2),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 40,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to Upload Outfit',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Supported formats: JPG, PNG',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Analyze Button
                GestureDetector(
                  onTap: _selectedImage != null && !_isLoading ? _analyzeOutfit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: _selectedImage != null && !_isLoading ? AppTheme.gradientAccent : null,
                      color: _selectedImage != null && !_isLoading ? null : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedImage != null && !_isLoading ? Colors.transparent : AppTheme.glassBorder,
                        width: 1.5,
                      ),
                      boxShadow: _selectedImage != null && !_isLoading
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(150),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'AI Stylist is thinking...',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: _selectedImage != null ? Colors.black : Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ANALYZE OUTFIT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _selectedImage != null ? Colors.black : Colors.white54,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Results Section
                if (_outfitData != null) ...[
                  // Visual Color Palette
                  if (_outfitData!['color_palette'] != null) ...[
                    Text(
                      'Recommended Color Palette',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (_outfitData!['color_palette'] as List).map((colorObj) {
                          final colorHex = colorObj['hex']?.toString() ?? '#FFFFFF';
                          final colorName = colorObj['name']?.toString() ?? '';
                          final parsedColor = _hexToColor(colorHex);
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: parsedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: parsedColor.withAlpha(100),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  colorName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  colorHex.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Overall Verdict
                  if (_outfitData!['overall_verdict'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Stylist Verdict',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      glowColor: AppTheme.primary,
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -10,
                            right: -10,
                            child: Icon(
                              Icons.format_quote_rounded,
                              size: 80,
                              color: Colors.white.withAlpha(15),
                            ),
                          ),
                          Text(
                            _outfitData!['overall_verdict'].toString(),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withAlpha(240),
                              fontSize: 16,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Fashion Categories Tabs
                  if (_outfitData!['categories'] != null) ...[
                    Text(
                      'Outfit Breakdown',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate((_outfitData!['categories'] as List).length, (index) {
                          final category = _outfitData!['categories'][index];
                          final isSelected = _selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary.withAlpha(20) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                category['name']?.toString() ?? 'Category',
                                style: GoogleFonts.outfit(
                                  color: isSelected ? AppTheme.primary : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Display Items for Selected Category
                    Builder(
                      builder: (context) {
                        final categories = _outfitData!['categories'] as List;
                        if (categories.isEmpty || _selectedCategoryIndex >= categories.length) return const SizedBox();
                        
                        final items = categories[_selectedCategoryIndex]['items'] as List?;
                        if (items == null || items.isEmpty) return const SizedBox();

                        return Column(
                          children: items.map((item) {
                            final type = item['type']?.toString() ?? 'Item';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GlassContainer(
                                glowColor: AppTheme.primary.withAlpha(50),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withAlpha(20),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_getIconForType(type), color: AppTheme.primary, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          type,
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      item['description']?.toString() ?? '',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withAlpha(230),
                                        fontSize: 15,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
