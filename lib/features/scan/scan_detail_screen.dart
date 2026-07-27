import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme.dart';
import '../../core/providers/scan_history_provider.dart';
import '../share/glow_up_share_screen.dart';
import '../../core/widgets/exit_survey_dialog.dart';

class ScanDetailScreen extends ConsumerStatefulWidget {
  final ScanRecord scan;
  final ScanRecord? previousScan;
  final bool fromHistory;

  const ScanDetailScreen({
    super.key,
    required this.scan,
    this.previousScan,
    this.fromHistory = false,
  });

  @override
  ConsumerState<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends ConsumerState<ScanDetailScreen>
    with TickerProviderStateMixin {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _canPop = false;

  late AnimationController _scoreAnim;
  late AnimationController _floatController;
  late Animation<double> _scoreProgress;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    
    double norm = widget.scan.auraScore > 10.0 ? widget.scan.auraScore / 10.0 : widget.scan.auraScore;
    _scoreProgress = Tween<double>(begin: 0, end: norm / 10.0)
        .animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOutCubic));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  double _norm(double s) => s > 10.0 ? s / 10.0 : s;

  String _tierLabel(double score) {
    if (score >= 90) return '💎 DIAMOND';
    if (score >= 80) return '🥇 GOLD';
    return '🥈 SILVER';
  }

  List<Color> _tierGradient(double score) {
    if (score >= 90) return const [Color(0xFF1AD6FD), Color(0xFF1153FC), Color(0xFFB44FFF)];
    if (score >= 80) return const [Color(0xFFFFD700), Color(0xFFFFa500), Color(0xFFFF6B00)];
    return const [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFF455A64)];
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Legendary': return const Color(0xFFFFD700);
      case 'Elite':     return AppTheme.secondary;
      case 'Rising':    return AppTheme.primary;
      default:          return AppTheme.textSecondary;
    }
  }

  void _openShareCardScreen() {
    final scans = ref.read(scanHistoryProvider);
    final idx = scans.indexOf(widget.scan);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlowUpShareScreen(initialIndex: idx >= 0 ? idx : 0),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;
    final prev = widget.previousScan;
    final normScore = _norm(scan.auraScore);
    final delta = prev != null ? normScore - _norm(prev.auraScore) : null;
    final ratingColor = _ratingColor(scan.rating);
    final tierScore = scan.auraScore > 10.0 ? scan.auraScore : scan.auraScore * 10;
    final tierColors = _tierGradient(tierScore);
    final tierTop = tierColors[0];
    final tierMid = tierColors[1];
    final bool canPopState = Navigator.canPop(context);

    return PopScope(
      canPop: _canPop || widget.fromHistory,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.fromHistory) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => const ExitSurveyDialog(collectionName: 'pre_scan'),
        );

        if (shouldPop == true) {
          setState(() => _canPop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              }
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Animated gradient background ─────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF090617),
                    const Color(0xFF0F0B24),
                    tierTop.withAlpha(35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── Radial glow top-right ─────────────────────────────────────────
            Positioned(
              top: -60,
              right: -80,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [tierTop.withAlpha(60), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [tierMid.withAlpha(40), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Main scrollable content ──────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Fixed top bar
                  _buildTopBar(tierTop),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Hero
                        SliverToBoxAdapter(
                          child: _buildHero(scan, normScore, delta, ratingColor, tierColors),
                        ),
                        // Content
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Shareable card
                                RepaintBoundary(
                                  key: _shareCardKey,
                                  child: _buildShareCard(scan, prev, delta, ratingColor, tierColors),
                                ),
                                const SizedBox(height: 28),

                                // AI Highlights
                                _buildSectionHeader('🤖 AI COACH INSIGHTS'),
                                const SizedBox(height: 12),
                                if (scan.fullData?['analytics']?['reports']?['aura']?['items'] != null)
                                  ...((scan.fullData!['analytics']['reports']['aura']['items'] as List)
                                      .map((h) => _buildHighlightTile(h.toString())))
                                else
                                  ...scan.highlights.map((h) => _buildHighlightTile(h)),
                                const SizedBox(height: 28),

                                // Score comparison
                                if (prev != null) ...[
                                  _buildSectionHeader('📊 SCORE COMPARISON'),
                                  const SizedBox(height: 12),
                                  _buildComparisonTable(scan, prev),
                                  const SizedBox(height: 28),
                                ],

                                // Comprehensive Analysis
                                _buildSectionHeader('🌟 COMPREHENSIVE ANALYSIS'),
                                const SizedBox(height: 12),
                                _buildComprehensiveGrid(scan),
                                const SizedBox(height: 28),

                                // 2×2 Detailed Metrics
                                _buildSectionHeader('📐 DETAILED METRICS'),
                                const SizedBox(height: 12),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 2.2,
                                  children: [
                                    _buildCompCard('Jawline', '${scan.jawlineScore.toStringAsFixed(0)}/100', '📐', AppTheme.secondary),
                                    _buildCompCard('Skin', '${scan.skinScore.toStringAsFixed(0)}/100', '✨', const Color(0xFF00CFFF)),
                                    _buildCompCard('Eyes', '${scan.eyeScore.toStringAsFixed(0)}/100', '👁️', AppTheme.primary),
                                    _buildCompCard('Posture', '${scan.postureScore.toStringAsFixed(0)}/100', '🏋️', AppTheme.success),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // AI Insight lists
                                _buildSectionHeader('🧠 DETAILED INSIGHTS'),
                                const SizedBox(height: 12),
                                _buildAiInsightList('structure'),
                                _buildAiInsightList('skin'),
                                _buildAiInsightList('eyes'),
                                _buildAiInsightList('posture'),
                                const SizedBox(height: 160),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky bottom buttons ────────────────────────────────────────
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(child: _buildHomeButton(canPopState)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShareFAB(tierColors)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(Color tierTop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(40), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const Spacer(),
          Text(
            'GrowUp AI REPORT',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openShareCardScreen,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.secondary.withAlpha(80), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Floating hero ────────────────────────────────────────────────────────────
  Widget _buildHero(ScanRecord scan, double normScore, double? delta,
      Color ratingColor, List<Color> tierColors) {
    final tierTop = tierColors[0];
    final tierMid = tierColors[1];
    final tierScore = scan.auraScore > 10.0 ? scan.auraScore : scan.auraScore * 10;
    final tierLabel = _tierLabel(tierScore);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Floating score ring
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow blob
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [tierTop.withAlpha(70), Colors.transparent],
                    ),
                  ),
                ),
                // Score ring
                AnimatedBuilder(
                  animation: _scoreProgress,
                  builder: (_, child) => SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130, height: 130,
                          child: CircularProgressIndicator(
                            value: _scoreProgress.value,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withAlpha(15),
                            valueColor: AlwaysStoppedAnimation<Color>(tierTop),
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [tierTop.withAlpha(40), tierMid.withAlpha(20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tierTop.withAlpha(80),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (_scoreProgress.value * 10.0).toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'GrowUp AI',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: tierTop,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Right side: Badge, Rating, Date, Delta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tier badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tierTop.withAlpha(60), tierMid.withAlpha(40)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tierTop.withAlpha(100), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: tierTop.withAlpha(50), blurRadius: 12),
                    ],
                  ),
                  child: Text(
                    tierLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Rating label with glow
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [tierTop, Colors.white, tierTop],
                  ).createShader(bounds),
                  child: Text(
                    scan.rating.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(scan.date),
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                ),
                if (delta != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (delta >= 0 ? AppTheme.success : AppTheme.danger).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (delta >= 0 ? AppTheme.success : AppTheme.danger).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: delta >= 0 ? AppTheme.success : AppTheme.danger,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} from last scan',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: delta >= 0 ? AppTheme.success : AppTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shareable Card ──────────────────────────────────────────────────────────
  Widget _buildShareCard(ScanRecord scan, ScanRecord? prev, double? delta, Color ratingColor, List<Color> tierColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColors[0].withAlpha(90), tierColors[1].withAlpha(60), tierColors[2].withAlpha(30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tierColors[0].withAlpha(100), width: 1.5),
        boxShadow: [BoxShadow(color: tierColors[0].withAlpha(50), blurRadius: 40, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withAlpha(40),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'GROWUP AI',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: ratingColor),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        DateFormat('d MMM yyyy').format(scan.date),
                        style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _norm(scan.auraScore).toStringAsFixed(1),
                          style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                        ),
                        Text('AURA SCORE', style: GoogleFonts.outfit(fontSize: 9, letterSpacing: 2.0, color: ratingColor, fontWeight: FontWeight.bold)),
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
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white60),
                          ),
                          if (delta != null)
                            Text(
                              '${delta >= 0 ? '▲' : '▼'} ${delta.abs().toStringAsFixed(1)} pts',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold,
                                  color: delta >= 0 ? AppTheme.success : AppTheme.danger),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.success.withAlpha(40), AppTheme.success.withAlpha(10)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.success.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_graph_rounded, color: AppTheme.success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'From ${_norm(prev.auraScore).toStringAsFixed(1)} → ${_norm(scan.auraScore).toStringAsFixed(1)} GrowUp AI • growup.ai',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareBadge(String rating, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Text(
          rating.toUpperCase(),
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0),
        ),
      );

  Widget _buildShareMetric(String label, double score) => Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(score.toStringAsFixed(0),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      );

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(18), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Container(
                      color: i.isEven ? Colors.white.withAlpha(5) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(child: Text(m.$1, style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold))),
                          Text(m.$2.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          SizedBox(width: 50, child: Text(m.$3.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white))),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 40,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: gain >= 0 ? AppTheme.success.withAlpha(20) : AppTheme.danger.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: gain >= 0 ? AppTheme.success.withAlpha(60) : AppTheme.danger.withAlpha(60)),
                              ),
                              child: Text(
                                '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(0)}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold,
                                    color: gain >= 0 ? AppTheme.success : AppTheme.danger),
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
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle({Color color = Colors.white38}) => GoogleFonts.outfit(
        fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: color);



  // ─── Comprehensive Grid ──────────────────────────────────────────────────────
  Widget _buildComprehensiveGrid(ScanRecord scan) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildCompCard('Face Shape', scan.faceShape, '🎭', AppTheme.primary),
        _buildCompCard('Symmetry', '${scan.faceSymmetry.toStringAsFixed(1)}%', '📐', AppTheme.secondary),
        _buildCompCard('Skin Health', '${scan.skinHealthScore.toStringAsFixed(1)}%', '✨', const Color(0xFF00CFFF)),
        _buildCompCard('Acne', scan.acneDetection, '🔍', AppTheme.success),
        _buildCompCard('Est. Age', '${scan.faceAgeEstimation} yrs', '⏳', Colors.orange),
        _buildCompCard('Dark Circles', scan.darkCircles, '👁️', Colors.purpleAccent),
        _buildCompCard('Hair Density', '${scan.hairDensity.toStringAsFixed(1)}%', '💇', Colors.pinkAccent),
        _buildCompCard('AI Face Score', '${scan.overallAiFaceScore.toStringAsFixed(1)}%', '🤖', AppTheme.primaryGlow),
      ],
    );
  }

  Widget _buildCompCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(20), Colors.black.withAlpha(60)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(40), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withAlpha(40), color.withAlpha(10)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            width: 6, height: 6,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, height: 1.5))),
        ],
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AppTheme.textSecondary),
    );
  }

  // ─── Share FAB ───────────────────────────────────────────────────────────────
  Widget _buildShareFAB(List<Color> tierColors) {
    return GestureDetector(
      onTap: _openShareCardScreen,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tierColors.take(2).toList(),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: tierColors[0].withAlpha(100), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'SHARE CARD 🔥',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Home button ─────────────────────────────────────────────────────────────
  Widget _buildHomeButton(bool canPop) {
    return GestureDetector(
      onTap: () {
        if (canPop) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'HOME',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Insight List ─────────────────────────────────────────────────────────
  Widget _buildAiInsightList(String category) {
    final fullData = widget.scan.fullData;
    if (fullData == null) return const SizedBox.shrink();
    final reports = fullData['analytics']?['reports'];
    if (reports == null || reports[category] == null) return const SizedBox.shrink();
    final items = reports[category]['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.toString(),
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withAlpha(215), height: 1.5),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
