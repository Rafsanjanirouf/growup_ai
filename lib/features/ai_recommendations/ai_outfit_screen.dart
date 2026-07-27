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
import '../../core/widgets/usage_limit_progress_bar.dart';

import '../../core/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AiOutfitScreen extends ConsumerStatefulWidget {
  const AiOutfitScreen({super.key});

  @override
  ConsumerState<AiOutfitScreen> createState() => _AiOutfitScreenState();
}

class _AiOutfitScreenState extends ConsumerState<AiOutfitScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _outfitData;
  int _selectedCategoryIndex = 0;
  String _selectedBudget = 'Mid-range';

  int _usedOutfit = 0;
  int _outfitLimit = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Budget gradient palettes
  static const Map<String, List<Color>> _budgetGradients = {
    'Budget':    [Color(0xFF1E3A5F), Color(0xFF0D2137)],
    'Mid-range': [Color(0xFF2D1B69), Color(0xFF1A1A4E)],
    'Premium':   [Color(0xFF5A2D00), Color(0xFF2E1500)],
  };
  static const Map<String, Color> _budgetAccents = {
    'Budget':    Color(0xFF4A9EE8),
    'Mid-range': Color(0xFF7C6EF5),
    'Premium':   Color(0xFFFFB347),
  };

  // Category gradient palettes (cycles)
  static const List<List<Color>> _catGradients = [
    [Color(0xFF1A2E4A), Color(0xFF0D1E35)],
    [Color(0xFF1E2A1A), Color(0xFF0D1A0D)],
    [Color(0xFF2A1A2E), Color(0xFF1A0D1E)],
    [Color(0xFF2A2A1A), Color(0xFF1A1A0D)],
    [Color(0xFF2A1A1A), Color(0xFF1A0D0D)],
    [Color(0xFF1A2A2A), Color(0xFF0D1A1A)],
  ];
  static const List<Color> _catAccents = [
    Color(0xFF4A9EE8),
    Color(0xFF4AE8A0),
    Color(0xFF7C6EF5),
    Color(0xFFE8C44A),
    Color(0xFFE84A6E),
    Color(0xFF4AE8D8),
  ];

  final List<Map<String, dynamic>> _budgetOptions = [
    {'label': 'Budget',    'icon': Icons.savings_rounded,     'desc': '< ₹2K'},
    {'label': 'Mid-range', 'icon': Icons.credit_card_rounded, 'desc': '₹2K–10K'},
    {'label': 'Premium',   'icon': Icons.diamond_rounded,     'desc': '₹10K+'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLimits();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLimits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final used  = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
      final limit = await FirestoreService().getDailyImageToTextLimit();
      if (mounted) setState(() { _usedOutfit = used; _outfitLimit = limit; });
    }
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('top') || t.contains('shirt') || t.contains('jacket')) return Icons.checkroom_rounded;
    if (t.contains('bottom') || t.contains('pant') || t.contains('jeans'))  return Icons.airline_seat_legroom_normal_rounded;
    if (t.contains('foot') || t.contains('shoe') || t.contains('sneaker'))  return Icons.roller_skating_rounded;
    if (t.contains('access') || t.contains('watch') || t.contains('glass')) return Icons.watch_rounded;
    if (t.contains('outfit'))                                                 return Icons.accessibility_new_rounded;
    if (t.contains('gym') || t.contains('sport'))                            return Icons.fitness_center_rounded;
    return Icons.checkroom_rounded;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker     = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _outfitData    = null;
        _selectedCategoryIndex = 0;
      });
      _animController.reset();
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text('Choose Photo Source',
              style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _sourceButton(ctx: ctx, icon: Icons.camera_alt_rounded,    label: 'Camera',  source: ImageSource.camera,  gradient: [const Color(0xFF1A3A5C), const Color(0xFF0D2137)], accent: const Color(0xFF4A9EE8))),
                const SizedBox(width: 12),
                Expanded(child: _sourceButton(ctx: ctx, icon: Icons.photo_library_rounded, label: 'Gallery', source: ImageSource.gallery, gradient: [const Color(0xFF2D1B69), const Color(0xFF1A1A4E)], accent: const Color(0xFF7C6EF5))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required ImageSource source,
    required List<Color> gradient,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: () { Navigator.pop(ctx); _pickImage(source); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 34),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeOutfit() async {
    if (_selectedImage == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final used  = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
      final limit = await FirestoreService().getDailyImageToTextLimit();
      if (used >= limit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Daily AI limit reached! ($limit generations). Try again tomorrow.', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 4),
          ));
        }
        return;
      }
    }

    setState(() { _isLoading = true; _outfitData = null; _selectedCategoryIndex = 0; });

    final language = ref.read(userStateProvider).coachLanguage;
    final data = await GeminiService.generateOutfitRecommendations(
      _selectedImage!.path,
      language: language,
      budget: _selectedBudget,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (data.isNotEmpty) {
      if (data['is_human_detected'] == false) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Invalid Image', style: GoogleFonts.outfit(color: AppTheme.danger, fontWeight: FontWeight.bold)),
            content: Text(data['error_message'] ?? 'Please upload a photo of a person.', style: GoogleFonts.outfit(color: Colors.white)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: GoogleFonts.outfit(color: AppTheme.primary)))],
          ),
        );
      } else if (data.containsKey('categories')) {
        setState(() => _outfitData = data);
        _animController.forward();

        if (user != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          FirestoreService().trackImageToTextUsage(userId: user.uid, dateKey: dateKey);
          final scanId   = DateTime.now().millisecondsSinceEpoch.toString();
          final imageUrl = await FirestoreService().uploadImage(_selectedImage!.path, user.uid, scanId);
          
          final record = OutfitRecord(
            id: scanId,
            userId: user.uid,
            date: DateTime.now(),
            imagePath: imageUrl,
            fullData: data,
          );
          await ref.read(outfitHistoryProvider.notifier).addOutfitScan(record);
          
          final updatedUsed = await FirestoreService().getDailyImageToTextUsage(userId: user.uid, dateKey: dateKey);
          if (mounted) setState(() => _usedOutfit = updatedUsed);
        }
      }
    }
  }

  Color _hexToColor(String hex) {
    final buf = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buf.write('ff');
    buf.write(hex.replaceFirst('#', ''));
    return Color(int.tryParse(buf.toString(), radix: 16) ?? 0xFFFFFFFF);
  }

  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF00E676);
    if (score >= 80) return const Color(0xFF69F0AE);
    if (score >= 70) return AppTheme.secondary;
    return Colors.orangeAccent;
  }

  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final budgetAccent = _budgetAccents[_selectedBudget] ?? AppTheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UsageLimitProgressBar(
                  title: 'Daily AI Stylist',
                  used: _usedOutfit,
                  limit: _outfitLimit,
                  icon: Icons.checkroom_rounded,
                ),
                const SizedBox(height: 20),

                // ── Budget Selector ─────────────────────────────────────────
                _gradientLabel('BUDGET TIER', Icons.savings_rounded),
                const SizedBox(height: 10),
                _buildBudgetSelector(),
                const SizedBox(height: 20),

                // ── Image Picker ────────────────────────────────────────────
                _buildImagePicker(budgetAccent),
                const SizedBox(height: 18),

                // ── Analyze Button ──────────────────────────────────────────
                _buildAnalyzeButton(budgetAccent),
                const SizedBox(height: 32),

                // ── Results ─────────────────────────────────────────────────
                if (_outfitData != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildResults(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2D1B69), Color(0xFF1A1A4E)]),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF7C6EF5).withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
      ),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF7C6EF5), Color(0xFF4A9EE8)],
          ).createShader(b),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text('AI Stylist',
          style: GoogleFonts.cinzel(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w900, letterSpacing: 2.0,
            shadows: [Shadow(color: const Color(0xFF7C6EF5).withAlpha(120), blurRadius: 10)],
          )),
      ],
    ),
    actions: [
      _langButton(),
      IconButton(
        icon: const Icon(Icons.history_rounded, color: Colors.white70),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OutfitHistoryScreen())),
      ),
    ],
  );

  Widget _langButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: GestureDetector(
      onTap: () async {
        final currentLang = ref.read(userStateProvider).coachLanguage;
        final chosen = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          isDismissible: true, enableDrag: true, isScrollControlled: true,
          builder: (ctx) => LanguagePickerSheet(selectedLanguage: currentLang),
        );
        if (chosen != null) ref.read(userStateProvider.notifier).updateLanguage(chosen);
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A2E4A), Color(0xFF0D1E35)]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ref.watch(userStateProvider).coachLanguage,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
              const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    ),
  );

  // ── Budget Selector ────────────────────────────────────────────────────────
  Widget _buildBudgetSelector() {
    return Row(
      children: _budgetOptions.map((opt) {
        final label     = opt['label'] as String;
        final isSelected = _selectedBudget == label;
        final gradient  = _budgetGradients[label] ?? [AppTheme.surface, AppTheme.surface2];
        final accent    = _budgetAccents[label] ?? AppTheme.primary;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedBudget = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)
                    : null,
                color: isSelected ? null : const Color(0xFF12121F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accent.withValues(alpha: 0.55) : Colors.white12,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(opt['icon'] as IconData,
                    color: isSelected ? accent : Colors.white30, size: 22),
                  const SizedBox(height: 5),
                  Text(label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? accent : Colors.white38,
                      fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal)),
                  Text(opt['desc'] as String,
                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Image Picker ───────────────────────────────────────────────────────────
  Widget _buildImagePicker(Color accent) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 260,
        decoration: BoxDecoration(
          gradient: _selectedImage == null
              ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: _selectedImage != null ? 0.5 : 0.2), width: 1.5),
          boxShadow: _selectedImage != null
              ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 6))]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Change photo button
                  Positioned(
                    bottom: 14, right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withValues(alpha: 0.5), accent.withValues(alpha: 0.3)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: accent.withValues(alpha: 0.6)),
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text('Change', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
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
                      gradient: LinearGradient(
                        colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.08)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded, size: 40, color: accent),
                  ),
                  const SizedBox(height: 16),
                  Text('Upload Your Photo',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: accent.withValues(alpha: 0.6), size: 13),
                      const SizedBox(width: 4),
                      Text('Camera or Gallery',
                        style: GoogleFonts.outfit(color: accent.withValues(alpha: 0.7), fontSize: 13)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // ── Analyze Button ─────────────────────────────────────────────────────────
  Widget _buildAnalyzeButton(Color accent) {
    final active = _selectedImage != null && !_isLoading;
    return GestureDetector(
      onTap: active ? _analyzeOutfit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.7)],
                )
              : null,
          color: active ? null : const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? Colors.transparent : Colors.white12, width: 1.5),
          boxShadow: active
              ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8))]
              : [],
        ),
        child: Center(
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('AI Stylist is analyzing...',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, fontStyle: FontStyle.italic)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                      color: active ? Colors.white : Colors.white24, size: 20),
                    const SizedBox(width: 8),
                    Text('ANALYZE — $_selectedBudget',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0,
                        color: active ? Colors.white : Colors.white24)),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────
  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // Appearance Analysis
        if (_outfitData!['appearance_analysis'] != null) ...[
          _gradientLabel('APPEARANCE ANALYSIS', Icons.face_retouching_natural_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A2A4A), Color(0xFF0D1A2E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4A9EE8).withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: const Color(0xFF4A9EE8).withValues(alpha: 0.1), blurRadius: 16)],
            ),
            child: Column(
              children: [
                Row(children: [
                  _analysisChip(Icons.accessibility_new_rounded, 'Body Type',   _outfitData!['appearance_analysis']['body_type']?.toString() ?? '—',   const Color(0xFF4A9EE8)),
                  const SizedBox(width: 10),
                  _analysisChip(Icons.palette_rounded,           'Skin Tone',   _outfitData!['appearance_analysis']['skin_tone']?.toString() ?? '—',   const Color(0xFF7C6EF5)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _analysisChip(Icons.crop_square_rounded,       'Face Shape',  _outfitData!['appearance_analysis']['face_shape']?.toString() ?? '—',  const Color(0xFF4AE8A0)),
                  const SizedBox(width: 10),
                  _analysisChip(Icons.style_rounded,             'Style Persona',_outfitData!['appearance_analysis']['style_persona']?.toString() ?? '—',const Color(0xFFFFB347)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Color Palette
        if (_outfitData!['color_palette'] != null) ...[
          _gradientLabel('COLOR PALETTE', Icons.color_lens_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (_outfitData!['color_palette'] as List).map((colorObj) {
                  final hex   = colorObj['hex']?.toString() ?? '#FFF';
                  final name  = colorObj['name']?.toString() ?? '';
                  final color = _hexToColor(hex);
                  return Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Column(
                      children: [
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.6)]),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 1)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(hex.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 0.8)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Verdict
        if (_outfitData!['overall_verdict'] != null) ...[
          _gradientLabel('STYLIST VERDICT', Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF2D1B69), Color(0xFF1A1A4E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7C6EF5).withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: const Color(0xFF7C6EF5).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -8, right: -8,
                  child: Icon(Icons.format_quote_rounded, size: 70, color: const Color(0xFF7C6EF5).withValues(alpha: 0.12)),
                ),
                Text(
                  _outfitData!['overall_verdict'].toString(),
                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.75, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Categories
        if (_outfitData!['categories'] != null) ...[
          _gradientLabel('OUTFIT BREAKDOWN', Icons.style_rounded),
          const SizedBox(height: 12),

          // Category tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate((_outfitData!['categories'] as List).length, (idx) {
                final cat        = _outfitData!['categories'][idx];
                final isSelected = _selectedCategoryIndex == idx;
                final accent     = _catAccents[idx % _catAccents.length];
                final gradient   = _catGradients[idx % _catGradients.length];
                final score      = (cat['match_score'] as num?)?.toInt() ?? 0;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)
                          : null,
                      color: isSelected ? null : const Color(0xFF12121F),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? accent.withValues(alpha: 0.6) : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat['name']?.toString() ?? 'Category',
                          style: GoogleFonts.outfit(
                            color: isSelected ? accent : Colors.white54,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                            fontSize: 13)),
                        if (score > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_scoreColor(score).withValues(alpha: 0.25), _scoreColor(score).withValues(alpha: 0.1)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$score%',
                              style: GoogleFonts.outfit(color: _scoreColor(score), fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Category content
          Builder(builder: (context) {
            final cats = _outfitData!['categories'] as List;
            if (cats.isEmpty || _selectedCategoryIndex >= cats.length) return const SizedBox();
            final selected = cats[_selectedCategoryIndex];
            final items    = selected['items'] as List?;
            final occasion = selected['occasion']?.toString();
            final score    = (selected['match_score'] as num?)?.toInt() ?? 0;
            final accent   = _catAccents[_selectedCategoryIndex % _catAccents.length];
            final gradient = _catGradients[_selectedCategoryIndex % _catGradients.length];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Occasion + Match score banner
                if (occasion != null || score > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, color: accent.withValues(alpha: 0.8), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(occasion ?? '',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
                        if (score > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_scoreColor(score).withValues(alpha: 0.2), _scoreColor(score).withValues(alpha: 0.08)]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _scoreColor(score).withValues(alpha: 0.4)),
                            ),
                            child: Text('Match $score%',
                              style: GoogleFonts.outfit(color: _scoreColor(score), fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                  ),

                if (items != null)
                  ...items.map((item) {
                    final type = item['type']?.toString() ?? 'Item';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [gradient[0].withValues(alpha: 0.9), gradient[1]],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.1)]),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIconForType(type), color: accent, size: 17),
                            ),
                            const SizedBox(width: 10),
                            Text(type.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: accent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ]),
                          const SizedBox(height: 10),
                          Text(item['description']?.toString() ?? '',
                            style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.65)),
                        ],
                      ),
                    );
                  }),
              ],
            );
          }),
        ],
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _gradientLabel(String text, IconData icon) => Row(
    children: [
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFF7C6EF5), Color(0xFF4A9EE8)],
        ).createShader(b),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 8),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFF7C6EF5), Color(0xFF4A9EE8)],
        ).createShader(b),
        child: Text(text,
          style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w900, letterSpacing: 2.0)),
      ),
    ],
  );

  Widget _analysisChip(IconData icon, String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: accent, size: 13),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.outfit(color: accent.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 0.4)),
            ]),
            const SizedBox(height: 5),
            Text(value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
