import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/scan_history_provider.dart';
import '../share/viral_share_service.dart';

class ScanDetailScreen extends ConsumerStatefulWidget {
  final ScanRecord scan;
  final ScanRecord? previousScan;

  const ScanDetailScreen({
    super.key,
    required this.scan,
    this.previousScan,
  });

  @override
  ConsumerState<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends ConsumerState<ScanDetailScreen>
    with TickerProviderStateMixin {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  late AnimationController _scoreAnim;
  late Animation<double> _scoreProgress;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _scoreProgress = Tween<double>(begin: 0, end: widget.scan.auraScore / 100)
        .animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    super.dispose();
  }

  double _norm(double s) => s > 10.0 ? s / 10.0 : s;

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    await Future.delayed(const Duration(milliseconds: 80));
    final bytes = await ViralShareService.captureWidget(_shareCardKey);
    setState(() => _isSharing = false);

    if (bytes != null) {
      final normScore = widget.scan.auraScore > 10.0 ? widget.scan.auraScore / 10.0 : widget.scan.auraScore;
      await ViralShareService.shareGlowUpCard(
        bytes,
        text: '🔥 Aura Score: ${normScore.toStringAsFixed(1)} '
            '(${widget.scan.rating}) — powered by GrowUp AI '
            '#GlowUp #Lookmaxxing #AuraScore',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture card. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;
    final prev = widget.previousScan;
    final delta = prev != null ? _norm(scan.auraScore) - _norm(prev.auraScore) : null;
    final ratingColor = _ratingColor(scan.rating);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ─── Scrollable content ─────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // Collapsible header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppTheme.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Share button in AppBar
                  _isSharing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
                          ),
                          onPressed: _handleShare,
                        ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(scan, delta, ratingColor),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Shareable card (captured by RepaintBoundary) ──
                      RepaintBoundary(
                        key: _shareCardKey,
                        child: _buildShareCard(scan, prev, delta, ratingColor),
                      ),
                      const SizedBox(height: 28),

                      // ── AI Highlights ──
                      _buildSectionHeader('🤖 AI COACH INSIGHTS'),
                      const SizedBox(height: 12),
                      if (scan.fullData?['analytics']?['reports']?['aura']?['items'] != null)
                        ...((scan.fullData!['analytics']['reports']['aura']['items'] as List).map((h) => _buildHighlightTile(h.toString())))
                      else
                        ...scan.highlights.map((h) => _buildHighlightTile(h)),
                      const SizedBox(height: 28),

                      // ── Before/After comparison ──
                      if (prev != null) ...[
                        _buildSectionHeader('📊 SCORE COMPARISON'),
                        const SizedBox(height: 12),
                        _buildComparisonTable(scan, prev),
                        const SizedBox(height: 28),
                      ],

                      // ── Full metric bars ──
                      _buildSectionHeader('📐 DETAILED METRICS'),
                      const SizedBox(height: 12),
                      _buildMetricBar('Jawline Symmetry', scan.jawlineScore, '📐', AppTheme.secondary),
                      _buildAiInsightList('structure'),
                      _buildMetricBar('Skin Clear Index', scan.skinScore, '✨', const Color(0xFF00CFFF)),
                      _buildAiInsightList('skin'),
                      _buildMetricBar('Eye Symmetry', scan.eyeScore, '👁️', AppTheme.primary),
                      _buildAiInsightList('eyes'),
                      _buildMetricBar('Posture Score', scan.postureScore, '🏋️', AppTheme.success),
                      _buildAiInsightList('posture'),
                      const SizedBox(height: 100), // space for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ─── Sticky Share Button ────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildShareFAB(),
          ),
        ],
      ),
    );
  }

  // ─── Hero header collapsible ────────────────────────────────────────────────
  Widget _buildHeroHeader(ScanRecord scan, double? delta, Color ratingColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.background, ratingColor.withAlpha(40), AppTheme.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Row(
            children: [
              // Animated score ring
              AnimatedBuilder(
                animation: _scoreProgress,
                builder: (context, child) => SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: _scoreProgress.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
                        ),
                      ),
                      // Big center score
                      Center(
                        child: Text(
                          (_norm(scan.auraScore) * _scoreProgress.value / (scan.auraScore / 100))
                              .toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      scan.rating.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ratingColor,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(scan.date),
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                    ),
                    Text(
                      scan.weekIndex > 0
                          ? 'Week ${scan.weekIndex} of ${scan.date.year}'
                          : 'Week ${scan.calendarWeekNumber} of ${scan.date.year}',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: delta >= 0 ? AppTheme.success : AppTheme.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} from last scan',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: delta >= 0 ? AppTheme.success : AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shareable Card (RepaintBoundary target) ────────────────────────────────
  Widget _buildShareCard(ScanRecord scan, ScanRecord? prev, double? delta, Color ratingColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D0025), Color(0xFF1A003A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ratingColor.withAlpha(80)),
        boxShadow: [
          BoxShadow(color: ratingColor.withAlpha(40), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          // Brand row
          Row(
            children: [
              Text(
                'GROWUP AI',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: AppTheme.secondary,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM yyyy').format(scan.date),
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Score + Week info row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big score at top right of image
                  Text(
                    _norm(scan.auraScore).toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'AURA SCORE',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      letterSpacing: 2.0,
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShareBadge(scan.rating, ratingColor),
                    const SizedBox(height: 8),
                    Text(
                      scan.weekIndex > 0 ? 'Week ${scan.weekIndex}' : 'Week ${scan.calendarWeekNumber}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white60,
                      ),
                    ),
                    if (delta != null)
                      Text(
                        '${delta >= 0 ? '▲' : '▼'} ${delta.abs().toStringAsFixed(1)} pts growth',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: delta >= 0 ? AppTheme.success : AppTheme.danger,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          // Metric mini grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShareMetric('📐 Jaw', scan.jawlineScore),
              _buildShareMetric('✨ Skin', scan.skinScore),
              _buildShareMetric('👁️ Eyes', scan.eyeScore),
              _buildShareMetric('🏋️ Posture', scan.postureScore),
            ],
          ),
          if (prev != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_graph_rounded, color: AppTheme.success, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'From ${_norm(prev.auraScore).toStringAsFixed(1)} → ${_norm(scan.auraScore).toStringAsFixed(1)} Aura • growup.ai',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareBadge(String rating, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        rating.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildShareMetric(String label, double score) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(
          score.toStringAsFixed(0),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Comparison Table ────────────────────────────────────────────────────────
  Widget _buildComparisonTable(ScanRecord scan, ScanRecord prev) {
    final metrics = [
      ('📐 Jawline', prev.jawlineScore, scan.jawlineScore),
      ('✨ Skin', prev.skinScore, scan.skinScore),
      ('👁️ Eyes', prev.eyeScore, scan.eyeScore),
      ('🏋️ Posture', prev.postureScore, scan.postureScore),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('METRIC', style: _tableHeaderStyle())),
                Text('BEFORE', style: _tableHeaderStyle()),
                const SizedBox(width: 20),
                SizedBox(width: 50, child: Text('AFTER', style: _tableHeaderStyle(color: AppTheme.success))),
                const SizedBox(width: 16),
                SizedBox(width: 40, child: Text('GAIN', style: _tableHeaderStyle())),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ...metrics.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final gain = m.$3 - m.$2;
            final isLast = i == metrics.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.$1,
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
                        ),
                      ),
                      Text(
                        m.$2.toStringAsFixed(0),
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 50,
                        child: Text(
                          m.$3.toStringAsFixed(0),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: gain >= 0 ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(color: Colors.white10, height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle({Color color = Colors.white38}) => GoogleFonts.outfit(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: color,
      );

  // ─── Metric Bar ──────────────────────────────────────────────────────────────
  Widget _buildMetricBar(String label, double score, String emoji, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${score.toStringAsFixed(0)}/100',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Highlight tile ──────────────────────────────────────────────────────────
  Widget _buildHighlightTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
        color: AppTheme.textSecondary,
      ),
    );
  }

  // ─── FAB share button ────────────────────────────────────────────────────────
  Widget _buildShareFAB() {
    return GestureDetector(
      onTap: _isSharing ? null : _handleShare,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: _isSharing
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isSharing
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.secondary.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSharing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              _isSharing ? 'GENERATING CARD...' : 'SHARE THIS SCAN RESULT 🔥',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Legendary':
        return const Color(0xFFFFD700);
      case 'Elite':
        return AppTheme.secondary;
      case 'Rising':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }

  // ─── AI Insight List ────────────────────────────────────────────────────────
  Widget _buildAiInsightList(String category) {
    final fullData = widget.scan.fullData;
    if (fullData == null) return const SizedBox.shrink();
    
    final reports = fullData['analytics']?['reports'];
    if (reports == null || reports[category] == null) return const SizedBox.shrink();

    final items = reports[category]['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0, left: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Text('✨', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
