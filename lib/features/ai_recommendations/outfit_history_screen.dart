import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/outfit_history_provider.dart';
import 'outfit_detail_screen.dart';

class OutfitHistoryScreen extends ConsumerWidget {
  const OutfitHistoryScreen({super.key});

  // Cycle through gradient palettes per card index
  static const List<List<Color>> _cardGradients = [
    [Color(0xFF1A1A4E), Color(0xFF2D1B69)],
    [Color(0xFF0D2137), Color(0xFF1A3A5C)],
    [Color(0xFF1A2E1A), Color(0xFF2D5A3D)],
    [Color(0xFF2E1A1A), Color(0xFF5A2D2D)],
    [Color(0xFF1A1E2E), Color(0xFF2D3A5A)],
    [Color(0xFF2E2A1A), Color(0xFF5A4A2D)],
  ];

  static const List<Color> _accentColors = [
    Color(0xFF7C6EF5),
    Color(0xFF4A9EE8),
    Color(0xFF4AE8A0),
    Color(0xFFE84A6E),
    Color(0xFF4A8EE8),
    Color(0xFFE8C44A),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(outfitHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF7C6EF5), Color(0xFF4A9EE8)],
              ).createShader(bounds),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Style History',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: history.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];
                  final gradient = _cardGradients[index % _cardGradients.length];
                  final accent = _accentColors[index % _accentColors.length];
                  final verdict = record.fullData['overall_verdict']?.toString() ?? 'Outfit Recommendation';
                  final categories = record.fullData['categories'] as List? ?? [];
                  final categoryCount = categories.length;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OutfitDetailScreen(record: record)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Top Row: Image + Content ──────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(22),
                                    bottomLeft: Radius.circular(0),
                                  ),
                                  child: SizedBox(
                                    width: 110,
                                    child: _buildThumbnail(record.imagePath, accent),
                                  ),
                                ),

                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Date + Delete row
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.1)],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: accent.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                DateFormat('MMM dd, yyyy').format(record.date),
                                                style: GoogleFonts.outfit(
                                                  color: accent,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () => ref.read(outfitHistoryProvider.notifier).deleteOutfitScan(record.id),
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Verdict
                                        Text(
                                          verdict,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Bottom: Category Pills ─────────────────────────
                          if (categoryCount > 0)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.1)],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(22),
                                  bottomRight: Radius.circular(22),
                                ),
                                border: Border(top: BorderSide(color: accent.withValues(alpha: 0.15))),
                              ),
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                              child: Row(
                                children: [
                                  Icon(Icons.style_rounded, color: accent.withValues(alpha: 0.7), size: 13),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: categories.take(6).map<Widget>((cat) {
                                          final name = cat['name']?.toString() ?? '';
                                          final score = (cat['match_score'] as num?)?.toInt();
                                          return Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: accent.withValues(alpha: 0.2)),
                                            ),
                                            child: Text(
                                              score != null ? '$name $score%' : name,
                                              style: GoogleFonts.outfit(
                                                color: accent.withValues(alpha: 0.9),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildThumbnail(String? imagePath, Color accent) {
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholderBox(accent),
          loadingBuilder: (ctx, child, progress) => progress == null
              ? child
              : Container(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
                ),
        );
      } else if (File(imagePath).existsSync()) {
        return Image.file(File(imagePath), fit: BoxFit.cover);
      }
    }
    return _placeholderBox(accent);
  }

  Widget _placeholderBox(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.1), accent.withValues(alpha: 0.05)],
        ),
      ),
      child: Center(
        child: Icon(Icons.checkroom_rounded, color: accent.withValues(alpha: 0.4), size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A4E), Color(0xFF2D1B69)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF7C6EF5).withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Color(0xFF7C6EF5).withValues(alpha: 0.2), blurRadius: 30),
              ],
            ),
            child: const Icon(Icons.checkroom_rounded, size: 52, color: Color(0xFF7C6EF5)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Style History Yet',
            style: GoogleFonts.cinzel(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first outfit photo\nto get AI style recommendations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
