import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/local_db_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import 'hair_style_image_fullscreen.dart';

class HairStyleHistoryScreen extends StatefulWidget {
  const HairStyleHistoryScreen({super.key});

  @override
  State<HairStyleHistoryScreen> createState() => _HairStyleHistoryScreenState();
}

class _HairStyleHistoryScreenState extends State<HairStyleHistoryScreen> {
  final LocalDbService _dbService = LocalDbService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    
    final records = await _dbService.getAllHairStyleScans(userId);
    setState(() {
      _history = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(String id) async {
    await _dbService.deleteHairStyleScan(id);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
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
          'History',
          style: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2.5,
            shadows: [
              Shadow(
                color: Colors.white.withAlpha(100),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _history.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            glowColor: AppTheme.primary,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withAlpha(20),
                    border: Border.all(color: AppTheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(50),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 64, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'No History Yet',
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your premium AI hairstyle\nreports will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final id = item['id'] as String;
        final dateStr = item['date'] as String;
        final imagePath = item['image_path'] as String?;
        
        final date = DateTime.tryParse(dateStr);
        final formattedDate = date != null
            ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
            : dateStr;

        final rawData = item['full_data'] as String;
        final data = jsonDecode(rawData);

        // Check if it's image mode
        final isImageMode = data['mode'] == 'image';
        
        String primaryStyleName = 'AI Hairstyle Match';
        if (!isImageMode) {
          final recommendations = data['recommendations'] as List<dynamic>? ?? [];
          if (recommendations.isNotEmpty) {
            primaryStyleName = recommendations.first['style_name'] ?? 'Premium Report';
          }
        } else {
          primaryStyleName = 'Premium Image Report';
        }

        return _buildHistoryCard(id, formattedDate, imagePath, primaryStyleName, data, isImageMode);
      },
    );
  }

  Widget _buildHistoryCard(String id, String date, String? imagePath, String primaryStyleName, Map<String, dynamic> data, bool isImageMode) {
    return GlassContainer(
      glowColor: AppTheme.primary,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isImageMode) {
              final imageResult = data['image_result'] as String?;
              if (imageResult != null && !imageResult.startsWith('http')) {
                // Determine if valid base64
                try {
                  base64Decode(imageResult);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HairStyleImageFullscreen(imageBase64: imageResult),
                    ),
                  );
                  return;
                } catch (_) {}
              }
              // Show text fallback if not base64 or if it failed
              _showTextFallbackSheet(imageResult ?? 'No result found');
            } else {
              _showDetailsSheet(data, imagePath);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (imagePath != null && File(imagePath).existsSync())
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(50),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(imagePath),
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withAlpha(50), width: 1.5),
                    ),
                    child: const Icon(Icons.face_retouching_natural, color: AppTheme.primary, size: 32),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.secondary.withAlpha(100)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isImageMode ? Icons.image : Icons.text_snippet, size: 12, color: AppTheme.secondary),
                            const SizedBox(width: 6),
                            Text(
                              isImageMode ? 'IMAGE REPORT' : 'TEXT REPORT',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        primaryStyleName,
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                      onPressed: () => _deleteRecord(id),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showTextFallbackSheet(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Premium Report',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailsSheet(Map<String, dynamic> data, String? imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Premium Report Details',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      if (imagePath != null && File(imagePath).existsSync())
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primary, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.primaryGlow,
                                  blurRadius: 20,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                File(imagePath),
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildReportContent(data),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    final faceAnalysis = data['face_shape_analysis'] ?? '';
    final symScore = data['symmetry_score'] ?? '-';
    final attractScore = data['attractiveness_score'] ?? '-';
    final youthScore = data['youthfulness_score'] ?? '-';
    final jawline = data['jawline'] ?? '-';
    final forehead = data['forehead'] ?? '-';
    final hairline = data['hairline'] ?? '-';
    final recommendations = data['recommendations'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TOP ANALYSIS SECTION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: AppTheme.secondary),
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
              const Divider(height: 32, color: Colors.white12),
              _buildAnalysisRow('Jawline', jawline),
              _buildAnalysisRow('Forehead', forehead),
              _buildAnalysisRow('Hairline', hairline),
              const SizedBox(height: 24),
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
          'Top Matches',
          style: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...recommendations.map((rec) => _buildDetailCard(rec)),
        const SizedBox(height: 40), // Bottom padding
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(String label, String score) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface2,
            border: Border.all(color: AppTheme.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.primaryGlow,
                blurRadius: 10,
              )
            ]
          ),
          child: Center(
            child: Text(
              score,
              style: GoogleFonts.outfit(
                fontSize: 14,
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
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(dynamic rec) {
    final rank = rec['rank'] ?? '';
    final name = rec['style_name'] ?? 'Hairstyle';
    final tag = rec['benefit_tag'] ?? '';
    final matchScore = rec['match_score'] ?? '';
    final desc = rec['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 1.5),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rank.toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Text(
                          rank.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    if (rank.toString().isNotEmpty) const SizedBox(width: 12),
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
                          if (tag.toString().isNotEmpty) const SizedBox(height: 6),
                          if (tag.toString().isNotEmpty)
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
          ),
          if (matchScore.toString().isNotEmpty)
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
                    matchScore.toString(),
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
                  text: '$label ',
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
}
