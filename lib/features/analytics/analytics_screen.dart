import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/providers/scan_history_provider.dart';
import '../scan/scan_history_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const AnalyticsScreen({super.key, this.isTab = false});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _activeTab = 'structure'; // 'structure' | 'skin' | 'hair' | 'eyes'
  String _selectedMarkerMessage = 'Tap a glowing point on the face to inspect AI lookmaxxing suggestions.';
  String _selectedMarkerTitle = 'GrowUp AI POINTER INSPECTOR';

  List<Map<String, dynamic>> _getMarkers(Map<String, dynamic>? analyticsData, ScanRecord? scan) {
    double randomPos(String seedStr, int offset) {
      final seed = seedStr.hashCode ^ (scan?.date.hashCode ?? 0) ^ offset;
      final rand = Random(seed);
      return 60.0 + rand.nextDouble() * 160.0;
    }

    if (analyticsData == null || analyticsData['markers'] == null) {
      // Fallback dummy data
      return [
        {'title': 'JAWLINE SYMMETRY', 'message': 'Symmetry is 86%.', 'top': randomPos('JAWLINE', 1), 'left': randomPos('JAWLINE', 2)},
        {'title': 'SKIN TEXTURE', 'message': 'Mild blemishes.', 'top': randomPos('SKIN', 1), 'left': randomPos('SKIN', 2)},
        {'title': 'EYE ALERTNESS', 'message': 'Slight dark circles.', 'top': randomPos('EYE', 1), 'left': randomPos('EYE', 2)},
        {'title': 'HAIR DENSITY', 'message': 'Good volume.', 'top': randomPos('HAIR', 1), 'left': randomPos('HAIR', 2)},
      ];
    }
    try {
      List<dynamic> markersList = analyticsData['markers'];
      return markersList.map((m) {
        final title = m['title']?.toString() ?? 'MARKER';
        return {
          'title': title,
          'message': m['message']?.toString() ?? '',
          'top': m.containsKey('top') ? (m['top'] as num).toDouble() : randomPos(title, 1),
          'left': m.containsKey('left') ? (m['left'] as num).toDouble() : randomPos(title, 2),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _getMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }

  @override
  Widget build(BuildContext context) {
    final scans = ref.watch(scanHistoryProvider);
    final latestScan = scans.isNotEmpty ? scans.first : null;
    final analyticsData = latestScan?.fullData?['analytics'] as Map<String, dynamic>?;

    final markers = _getMarkers(analyticsData, latestScan);

    // Calculate progress trend
    String trendText = 'Overall Glow Score +0.0%';
    Color trendColor = AppTheme.success;
    if (scans.length >= 2) {
      final current = scans[0].auraScore;
      final previous = scans[1].auraScore;
      final diff = current - previous;
      final pct = previous > 0 ? (diff / previous) * 100 : 0.0;
      final sign = diff >= 0 ? '+' : '';
      trendText = 'Overall Glow Score $sign${pct.toStringAsFixed(1)}%';
      trendColor = diff >= 0 ? AppTheme.success : AppTheme.danger;
    } else if (scans.isNotEmpty) {
      trendText = 'Initial Glow Score Established';
      trendColor = AppTheme.secondary;
    }

    double normScore(double raw) => raw > 10.0 ? raw / 10.0 : raw;

    // Build actual chart columns
    List<Widget> chartColumns = [];
    if (scans.isNotEmpty) {
      final recentScans = scans.take(4).toList().reversed.toList(); // get oldest to newest of the last 4
      double maxHeight = 100.0;
      double maxScore = 10.0;
      for (int i = 0; i < recentScans.length; i++) {
        final scan = recentScans[i];
        final val = normScore(scan.auraScore);
        final height = ((val / maxScore) * maxHeight).clamp(0.0, maxHeight);
        final isCurrent = (i == recentScans.length - 1);
        chartColumns.add(
          _buildBarChartColumn('Scn ${scan.weekIndex > 0 ? scan.weekIndex : (i+1)}', val, height, isCurrent),
        );
      }
    } else {
      chartColumns = [
        _buildBarChartColumn('Wk 1', 6.8, 60, false),
        _buildBarChartColumn('Wk 2', 7.1, 75, false),
        _buildBarChartColumn('Wk 3', 7.5, 90, false),
        _buildBarChartColumn('Wk 4', 7.8, 105, true),
      ];
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isTab)
                  // Top Header back button
                  Row(
                    children: [
                      if (!widget.isTab)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Flexible(
                        child: Text(
                          'AI ANALYTICS',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Scan History Button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanHistoryScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.secondary.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, color: AppTheme.secondary, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'HISTORY',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (latestScan != null) ...[
                  const SizedBox(height: 16),
                  GlassContainer(
                    glowColor: AppTheme.primary,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCAN DATE: ${latestScan.date.day.toString().padLeft(2, '0')} ${_getMonth(latestScan.date.month)} ${latestScan.date.year}',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AURA SCORE: ${normScore(latestScan.auraScore).toStringAsFixed(1)} / 10.0',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.secondary.withAlpha(100)),
                          ),
                          child: Text(
                            latestScan.rating.toUpperCase(),
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Interactive Face Pointer Card
                Text(
                  'INTERACTIVE SCAN BREAKDOWN',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Base Face Image
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(26),
                              blurRadius: 30,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Builder(
                            builder: (context) {
                              final path = latestScan?.imageUrl;
                              if (path == null || path.isEmpty) {
                                return Image.asset('assets/image/avater_image.png', fit: BoxFit.cover);
                              }
                              if (path.startsWith('http')) {
                                return Image.network(
                                  path, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Image.asset('assets/image/avater_image.png', fit: BoxFit.cover),
                                );
                              }
                              return Image.file(
                                File(path), 
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset('assets/image/avater_image.png', fit: BoxFit.cover),
                              );
                            },
                          ),
                        ),
                      ),

                      // Floating Interactive Pointer markers
                      ...markers.map((m) {
                        final isSelected = _selectedMarkerTitle == m['title'];
                        return Positioned(
                          top: m['top'] as double,
                          left: m['left'] as double,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMarkerTitle = m['title'] as String;
                                _selectedMarkerMessage = m['message'] as String;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isSelected ? 24 : 16,
                              height: isSelected ? 24 : 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppTheme.secondary : AppTheme.primary,
                                border: Border.all(color: Colors.white, width: 2.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected ? AppTheme.secondary : AppTheme.primary).withAlpha(180),
                                    blurRadius: isSelected ? 16 : 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(Icons.touch_app_rounded, color: Colors.white, size: 10),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Interactive Inspector Output Box
                GlassContainer(
                  glowColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.radar_rounded, color: AppTheme.secondary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _selectedMarkerTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedMarkerMessage,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tabs: Structure, Skin, Hair, Eyes
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFeatureTab('structure', '📐 Structure'),
                      _buildFeatureTab('skin', '🧼 Skin'),
                      _buildFeatureTab('hair', '💇 Hair'),
                      _buildFeatureTab('eyes', '👁️ Eyes'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Active Tab Content Card
                _buildFeatureReportCard(analyticsData),
                const SizedBox(height: 32),

                // Progress History Chart
                Text(
                  'GrowUp AI WEEKLY PROGRESS TRENDS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trendText,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your face structure and skin quality index is tracked over recent scans.',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      
                      // Custom Mock Line Chart using responsive rows
                      SizedBox(
                        height: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: chartColumns,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTab(String tabKey, String label) {
    final isSelected = _activeTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabKey),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(40) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartColumn(String label, double value, double height, bool isCurrent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toStringAsFixed(1),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isCurrent ? AppTheme.secondary : Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: isCurrent
                  ? [AppTheme.secondary, AppTheme.primary]
                  : [AppTheme.primary.withAlpha(128), AppTheme.primary.withAlpha(40)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFeatureReportCard(Map<String, dynamic>? analyticsData) {
    String title = '';
    String score = '';
    List<String> items = [];

    // Fallback data
    if (analyticsData == null || analyticsData['reports'] == null) {
      if (_activeTab == 'structure') {
        title = 'FACIAL STRUCTURE REPORT';
        score = 'Symmetry: 86%';
        items = ['Jawline: 8.2/10 (High Definition)', 'Recommendation: Mastic gum chewing 10m/day'];
      } else if (_activeTab == 'skin') {
        title = 'SKIN DERMATOLOGY INDEX';
        score = 'Clear Index: 78%';
        items = ['Texture: Oily base detected', 'Recommendation: Use vitamin C serum under eyes'];
      } else if (_activeTab == 'hair') {
        title = 'HAIR FOLLECTION STUDY';
        score = 'Density: 94%';
        items = ['Hairline: Safe baseline', 'Recommendation: Minimize direct sulfate treatments'];
      } else {
        title = 'EYE ANALYSIS REPORT';
        score = 'Alertness: 85%';
        items = ['Slight dark circles', 'Recommendation: Ice rollers in the morning'];
      }
    } else {
      final reports = analyticsData['reports'];
      final tabData = reports[_activeTab];
      
      if (_activeTab == 'structure') {
        title = 'FACIAL STRUCTURE REPORT';
      } else if (_activeTab == 'skin') {
        title = 'SKIN DERMATOLOGY INDEX';
      } else if (_activeTab == 'hair') {
        title = 'HAIR FOLLECTION STUDY';
      } else if (_activeTab == 'eyes') {
        title = 'EYE ANALYSIS REPORT';
      }

      if (tabData != null) {
        score = tabData['score']?.toString() ?? 'N/A';
        final itemsRaw = tabData['items'] as List<dynamic>?;
        if (itemsRaw != null) {
          items = itemsRaw.map((e) => e.toString()).toList();
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              Text(
                score,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'No specific AI recommendations available for this category yet.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.secondary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
