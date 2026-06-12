import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/scan_history_provider.dart';
import 'viral_share_service.dart';

class GlowUpShareScreen extends ConsumerStatefulWidget {
  const GlowUpShareScreen({super.key});

  @override
  ConsumerState<GlowUpShareScreen> createState() => _GlowUpShareScreenState();
}

class _GlowUpShareScreenState extends ConsumerState<GlowUpShareScreen>
    with TickerProviderStateMixin {
  final GlobalKey _shareKey = GlobalKey();
  bool _isCapturing = false;
  bool _isSharing = false;

  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleShare() async {
    setState(() => _isCapturing = true);
    await Future.delayed(const Duration(milliseconds: 100));

    final bytes = await ViralShareService.captureWidget(_shareKey);
    setState(() {
      _isCapturing = false;
      _isSharing = true;
    });

    if (bytes != null) {
      await ViralShareService.shareGlowUpCard(bytes);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate share card. Try again.')),
        );
      }
    }
    if (mounted) setState(() => _isSharing = false);
  }

  /// Build stat items from real scan data.
  /// - 2+ scans: compare latest vs previous (real delta shown)
  /// - 1 scan: show current score as NOW, and a realistic expected target (no delta)
  /// - 0 scans: fallback demo data
  List<_StatItem> _buildStatItems(List<ScanRecord> scans) {
    if (scans.isEmpty) {
      // Fallback: no scans yet — show demo without delta
      return [
        _StatItem('Jawline', 55, 62, '📐', hasPrevious: false),
        _StatItem('Skin', 50, 58, '✨', hasPrevious: false),
        _StatItem('Eyes', 60, 70, '👁️', hasPrevious: false),
        _StatItem('Posture', 40, 50, '🏋️', hasPrevious: false),
      ];
    }

    final latest = scans.first;

    if (scans.length == 1) {
      // Only one scan: show current scores as NOW, show expected target
      // Expected target = current + realistic improvement range (5-10 pts)
      int expectedJawline = (latest.jawlineScore + 8).clamp(0, 100).toInt();
      int expectedSkin    = (latest.skinScore    + 7).clamp(0, 100).toInt();
      int expectedEyes    = (latest.eyeScore     + 6).clamp(0, 100).toInt();
      int expectedPosture = (latest.postureScore + 10).clamp(0, 100).toInt();
      return [
        _StatItem('Jawline', latest.jawlineScore.toInt(), expectedJawline, '📐', hasPrevious: false),
        _StatItem('Skin',    latest.skinScore.toInt(),    expectedSkin,    '✨', hasPrevious: false),
        _StatItem('Eyes',    latest.eyeScore.toInt(),     expectedEyes,    '👁️', hasPrevious: false),
        _StatItem('Posture', latest.postureScore.toInt(), expectedPosture, '🏋️', hasPrevious: false),
      ];
    }

    // 2+ scans: real before/after
    final previous = scans[1]; // scans[0] = newest, scans[1] = previous
    return [
      _StatItem('Jawline', previous.jawlineScore.toInt(), latest.jawlineScore.toInt(), '📐', hasPrevious: true),
      _StatItem('Skin',    previous.skinScore.toInt(),    latest.skinScore.toInt(),    '✨', hasPrevious: true),
      _StatItem('Eyes',    previous.eyeScore.toInt(),     latest.eyeScore.toInt(),     '👁️', hasPrevious: true),
      _StatItem('Posture', previous.postureScore.toInt(), latest.postureScore.toInt(), '🏋️', hasPrevious: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStateProvider);
    final scans = ref.watch(scanHistoryProvider);

    final statItems = _buildStatItems(scans);
    final latestScan = scans.isNotEmpty ? scans.first : null;

    // Week label: use scan position (oldest scan = Week 1, next = Week 2, etc.)
    String weekLabel = '';
    if (latestScan != null) {
      if (latestScan.weekIndex > 0) {
        // weekIndex set by SyncService during push
        weekLabel = 'Week ${latestScan.weekIndex}';
      } else {
        // Fallback: compute from scan list position (oldest = Week 1)
        final sorted = [...scans]..sort((a, b) => a.date.compareTo(b.date));
        final position = sorted.indexWhere((s) => s.id == latestScan.id) + 1;
        weekLabel = 'Week $position';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'SHARE YOUR GLOW-UP',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
            if (weekLabel.isNotEmpty)
              Text(
                weekLabel,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.secondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Card Preview ────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: _buildCardPreview(user, scans, statItems, weekLabel),
            ),
          ),

          // ─── Scan info row ───────────────────────────────────────────────
          if (scans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded,
                      color: Colors.white38, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    scans.length == 1
                        ? 'Based on your ${scans.length} scan'
                        : 'Based on your ${scans.length} scans  •  ${latestScan?.rating ?? ""}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Action Buttons ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
            child: Column(
              children: [
                _ShareButton(
                  isLoading: _isCapturing || _isSharing,
                  onTap: _handleShare,
                ),
                const SizedBox(height: 12),
                Text(
                  'Card will be saved to your gallery and ready\nto share on Instagram, Snapchat, WhatsApp 🚀',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(
    UserState user,
    List<ScanRecord> scans,
    List<_StatItem> statItems,
    String weekLabel,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxH = constraints.maxHeight - 32;
      final maxW = constraints.maxWidth - 32;
      final h = maxH;
      final w = math.min(maxW, h * 9 / 16);

      return RepaintBoundary(
        key: _shareKey,
        child: SizedBox(
          width: w,
          height: h,
          child: _GlowUpCard(
            user: user,
            scans: scans,
            statItems: statItems,
            glowAnim: _glowAnim,
            pulseAnim: _pulseAnim,
            weekLabel: weekLabel,
          ),
        ),
      );
    });
  }
}

// ─── The Actual Share Card ─────────────────────────────────────────────────────
class _GlowUpCard extends StatelessWidget {
  final UserState user;
  final List<ScanRecord> scans;
  final List<_StatItem> statItems;
  final Animation<double> glowAnim;
  final Animation<double> pulseAnim;
  final String weekLabel;

  const _GlowUpCard({
    required this.user,
    required this.scans,
    required this.statItems,
    required this.glowAnim,
    required this.pulseAnim,
    required this.weekLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF03001C), Color(0xFF1A003A), Color(0xFF02000A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Decorative glowing orbs
            _GlowOrb(
                offset: const Offset(-60, -60),
                color: AppTheme.primary,
                size: 200),
            _GlowOrb(
                offset: const Offset(200, 280),
                color: AppTheme.secondary,
                size: 150),
            _GlowOrb(
                offset: const Offset(-40, 480),
                color: const Color(0xFF00FFCC),
                size: 120),

            // Grid lines overlay
            CustomPaint(size: Size.infinite, painter: _GridPainter()),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Brand Header with week ──
                  _buildBrandHeader(),
                  const SizedBox(height: 16),

                  // ── Aura Score Ring ──
                  AnimatedBuilder(
                    animation: Listenable.merge([glowAnim, pulseAnim]),
                    builder: (context, child) =>
                        _buildAuraRing(pulseAnim.value, glowAnim.value),
                  ),
                  const SizedBox(height: 14),

                  // ── Streak badge (if any) ──
                  if (user.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.orange.withAlpha(80)),
                      ),
                      child: Text(
                        '🔥 ${user.streak} DAY STREAK',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // ── Stats Before/After ──
                  _buildStatsSection(),
                  const Spacer(),

                  // ── Viral Footer ──
                  _buildViralFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GROWUP AI',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                color: AppTheme.secondary,
              ),
            ),
            Text(
              'MY GLOW-UP JOURNEY',
              style: GoogleFonts.outfit(
                fontSize: 8,
                letterSpacing: 1.5,
                color: Colors.white38,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔥 FLEX MODE',
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (weekLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                weekLabel.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  color: AppTheme.secondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAuraRing(double scale, double glow) {
    final aura = user.auraScore > 0 ? user.auraScore : 0.0;
    final displayAura = aura > 10.0 ? aura : aura * 10;
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withAlpha((glow * 120).toInt()),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: (displayAura / 100).clamp(0.0, 1.0),
                strokeWidth: 9,
                backgroundColor: Colors.white10,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayAura > 0 ? displayAura.toStringAsFixed(1) : '--',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AURA SCORE',
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final hasPrevious = statItems.isNotEmpty && statItems.first.hasPrevious;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'METRIC',
                  style: GoogleFonts.outfit(
                      fontSize: 7, letterSpacing: 1.5, color: Colors.white38),
                ),
              ),
              Text(
                hasPrevious ? 'BEFORE' : 'NOW',
                style: GoogleFonts.outfit(
                    fontSize: 7, letterSpacing: 1.5, color: Colors.white38),
              ),
              const SizedBox(width: 18),
              Text(
                hasPrevious ? 'NOW' : 'TARGET',
                style: GoogleFonts.outfit(
                    fontSize: 7,
                    letterSpacing: 1.5,
                    color: hasPrevious ? AppTheme.success : AppTheme.secondary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white12,
                Colors.transparent
              ],
            ),
          ),
        ),
        ...statItems.map((s) => _buildStatRow(s)),
      ],
    );
  }

  Widget _buildStatRow(_StatItem s) {
    final delta = s.after - s.before;
    final isImproved = delta >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(s.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (s.hasPrevious ? s.after : s.before).clamp(0, 100) / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      s.hasPrevious ? AppTheme.primary : AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Left column: BEFORE (if previous scan) or NOW (if first scan)
          Text(
            s.hasPrevious ? '${s.before}' : '${s.before}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          // Right column: NOW (if previous) or TARGET (if first scan)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.after}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: s.hasPrevious ? Colors.white : AppTheme.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              // Delta only shown if there's an actual previous scan to compare
              if (s.hasPrevious && delta != 0)
                Text(
                  '${isImproved ? "+" : ""}$delta',
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    color: isImproved ? AppTheme.success : AppTheme.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViralFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppTheme.primary, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#GlowUp  #Lookmaxxing',
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#GrowUpAI  #FlexFactor',
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border:
                    Border.all(color: AppTheme.secondary.withAlpha(80)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'growup.ai',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'JOIN THE GLOW UP →',
                    style: GoogleFonts.outfit(
                      fontSize: 6,
                      letterSpacing: 1.0,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Helper Classes & Widgets ──────────────────────────────────────────────────

class _StatItem {
  final String label;
  final int before;    // previous scan score (or current score if hasPrevious==false)
  final int after;     // current score (or expected target if hasPrevious==false)
  final String emoji;
  final bool hasPrevious; // true = real before/after; false = first scan (show target)
  const _StatItem(this.label, this.before, this.after, this.emoji, {required this.hasPrevious});
}

class _GlowOrb extends StatelessWidget {
  final Offset offset;
  final Color color;
  final double size;

  const _GlowOrb({
    required this.offset,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withAlpha(60), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Share Button with loading state ─────────────────────────────────────────
class _ShareButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _ShareButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                )
              : const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isLoading
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
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.ios_share_rounded,
                  color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              isLoading ? 'GENERATING...' : 'SHARE MY GLOW-UP 🔥',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
