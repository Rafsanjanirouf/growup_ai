import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/gemini_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/outfit_history_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'outfit_history_screen.dart';
import '../../core/widgets/language_picker_sheet.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/sync_service.dart';
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
          _outfitData = null;
        } else if (data.containsKey('categories')) {
          _outfitData = data;
          
          // Track Usage
          if (user != null) {
            final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
            FirestoreService().trackImageToTextUsage(userId: user.uid, dateKey: dateKey);
          }
          
          // Save to Local DB History
          final userId = user?.uid ?? 'anonymous';
          final newRecord = OutfitRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            date: DateTime.now(),
            imagePath: _selectedImage!.path,
            fullData: data,
          );
          ref.read(outfitHistoryProvider.notifier).addOutfitScan(newRecord);
          
          // Trigger background sync to upload to Firestore
          SyncService().syncPendingScans();
        }
      } else {
        // Fallback or error handling could go here.
      }
    });
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
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                                color: AppTheme.primary.withAlpha(100),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'ANALYZE OUTFIT',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _selectedImage != null ? Colors.black : Colors.white54,
                                letterSpacing: 1.5,
                              ),
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
                                    color: Colors.white70,
                                    fontSize: 12,
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withAlpha(20),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withAlpha(80), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(10),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Text(
                        _outfitData!['overall_verdict'].toString(),
                        style: GoogleFonts.outfit(
                          color: Colors.white.withAlpha(240),
                          fontSize: 16,
                          height: 1.6,
                        ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary.withAlpha(20) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
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
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface.withAlpha(150),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white10, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
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
