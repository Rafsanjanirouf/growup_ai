import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/scan_history_provider.dart';
import 'scan_detail_screen.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const ScanHistoryScreen({super.key, this.isTab = false});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scans = ref.watch(scanHistoryProvider);

    // Sort oldest first for week-index labels
    final sorted = List<ScanRecord>.from(scans)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Group by sequential week label (Week 1, Week 2, …)
    // A new week starts when it has been ≥7 days since the previous scan
    final List<_WeekGroup> weekGroups = _buildWeekGroups(sorted);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: _buildHeader(scans),
              ),
              Expanded(
                child: scans.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: weekGroups.length,
                        itemBuilder: (context, i) {
                          final group = weekGroups[i];
                          // Previous group's best score for delta
                          final prevBest = i > 0
                              ? weekGroups[i - 1].scans.map((s) => s.auraScore).reduce((a, b) => a > b ? a : b)
                              : null;
                          return _buildWeekGroup(group, prevBest, scans);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build sequential week groups ─────────────────────────────────────────
  List<_WeekGroup> _buildWeekGroups(List<ScanRecord> sorted) {
    if (sorted.isEmpty) return [];
    final groups = <_WeekGroup>[];
    int weekNum = 1;
    List<ScanRecord> current = [sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      final gap = sorted[i].date.difference(sorted[i - 1].date).inDays;
      if (gap >= 7) {
        groups.add(_WeekGroup(weekNum, List.from(current)));
        weekNum++;
        current = [];
      }
      current.add(sorted[i]);
    }
    groups.add(_WeekGroup(weekNum, current));

    // Return newest first
    return groups.reversed.toList();
  }

  // ─── Top Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(List<ScanRecord> scans) {
    double growthPct = 0;
    if (scans.length >= 2) {
      final sorted = List<ScanRecord>.from(scans)..sort((a, b) => a.date.compareTo(b.date));
      final first  = sorted.first.auraScore;
      final latest = sorted.last.auraScore;
      growthPct = first > 0 ? ((latest - first) / first) * 100 : 0;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.isTab) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                'SCAN HISTORY',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withAlpha(100)),
                ),
                child: Text(
                  '${scans.length} Scans',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (scans.length >= 2) ...[
            Row(
              children: [
                _buildStatChip(
                  '📈 Total Growth',
                  '${growthPct > 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                  growthPct >= 0 ? AppTheme.success : AppTheme.danger,
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  '🏆 Best Score',
                  scans.map((s) => s.auraScore).reduce((a, b) => a > b ? a : b).toStringAsFixed(1),
                  AppTheme.secondary,
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  '📅 Weeks',
                  '${_buildWeekGroups(List<ScanRecord>.from(scans)..sort((a, b) => a.date.compareTo(b.date))).length}',
                  AppTheme.warning,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 9, color: Colors.white54, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Week Group Section ─────────────────────────────────────────────────────
  Widget _buildWeekGroup(_WeekGroup group, double? prevBestScore, List<ScanRecord> allScans) {
    final bestScore = group.scans.map((s) => s.auraScore).reduce((a, b) => a > b ? a : b);
    final delta     = prevBestScore != null ? bestScore - prevBestScore : null;
    final dateRange = _weekDateRange(group.scans);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'WEEK ${group.weekNum}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dateRange,
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Week progress bar
          _buildWeekProgressBar(bestScore, delta),
          const SizedBox(height: 12),

          ...group.scans.reversed.map((scan) {
            final older = allScans.where((s) => s.date.isBefore(scan.date)).toList();
            final previousScan = older.isNotEmpty ? (older..sort((a, b) => b.date.compareTo(a.date))).first : null;
            return _buildScanCard(scan, previousScan);
          }),
        ],
      ),
    );
  }

  Widget _buildWeekProgressBar(double bestScore, double? delta) {
    final isPositive = delta == null || delta >= 0;
    final deltaColor = isPositive ? AppTheme.success : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best score this week',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: bestScore / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bestScore.toStringAsFixed(1),
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              if (delta != null)
                Text(
                  '${isPositive ? '▲ +' : '▼ '}${delta.abs().toStringAsFixed(1)}',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: deltaColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _weekDateRange(List<ScanRecord> scans) {
    final sorted = List<ScanRecord>.from(scans)..sort((a, b) => a.date.compareTo(b.date));
    final start  = DateFormat('d MMM').format(sorted.first.date);
    final end    = DateFormat('d MMM yyyy').format(sorted.last.date);
    return '$start – $end';
  }

  // ─── Single Scan Card ───────────────────────────────────────────────────────
  Widget _buildScanCard(ScanRecord scan, ScanRecord? previousScan) {
    final delta       = previousScan != null ? scan.auraScore - previousScan.auraScore : null;
    final ratingColor = _ratingColor(scan.rating);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanDetailScreen(scan: scan, previousScan: previousScan),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ratingColor.withAlpha(60), width: 1),
          boxShadow: [
            BoxShadow(
              color: ratingColor.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Scan thumbnail (black placeholder if no image)
            _buildThumbnail(scan.imageUrl),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEE, d MMM').format(scan.date),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildRatingBadge(scan.rating, ratingColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('hh:mm a · yyyy').format(scan.date),
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
                  ),
                  if (delta != null) ...[
                    const SizedBox(height: 5),
                    _buildDeltaBadge(delta),
                  ],
                  const SizedBox(height: 10),
                  // Mini stats bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('📐', 'Jaw', scan.jawlineScore),
                      _buildMiniStat('✨', 'Skin', scan.skinScore),
                      _buildMiniStat('👁️', 'Eyes', scan.eyeScore),
                      _buildMiniStat('🏋️', 'Post', scan.postureScore),
                      // Big aura score
                      Column(
                        children: [
                          Text('⚡', style: const TextStyle(fontSize: 10)),
                          Text(
                            scan.auraScore.toStringAsFixed(0),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: ratingColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  /// Shows scan thumbnail if image URL exists (local or cloud), otherwise shows a clean black box.
  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _blackBox();
    }

    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        height: 68,
        child: isNetwork
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, st) => _blackBox(),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return _blackBox();
                },
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                cacheWidth: 150, // Resizes before decoding to fix frame drops
                errorBuilder: (ctx, e, st) => _blackBox(),
              ),
      ),
    );
  }

  Widget _blackBox() => Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 20),
        ),
      );

  Widget _buildRatingBadge(String rating, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        rating.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildDeltaBadge(double delta) {
    final isPositive = delta >= 0;
    final color = isPositive ? AppTheme.success : AppTheme.danger;
    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: color,
          size: 13,
        ),
        const SizedBox(width: 4),
        Text(
          '${isPositive ? '▲ +' : '▼ '}${delta.abs().toStringAsFixed(1)} pts',
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String emoji, String label, double score) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 9)),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 8, color: Colors.white38),
        ),
        Text(
          score.toStringAsFixed(0),
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪞', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'NO SCANS YET',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first AI face scan\nto start tracking your Glow-Up journey!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Legendary': return const Color(0xFFFFD700);
      case 'Elite':     return AppTheme.secondary;
      case 'Rising':    return AppTheme.primary;
      default:          return AppTheme.textSecondary;
    }
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────
class _WeekGroup {
  final int weekNum;
  final List<ScanRecord> scans;
  _WeekGroup(this.weekNum, this.scans);
}
