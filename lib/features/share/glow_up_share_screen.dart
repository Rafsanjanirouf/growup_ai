import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../../core/providers/user_provider.dart';
import '../../core/providers/scan_history_provider.dart';
import 'viral_share_service.dart';

enum CardTier { silver, gold, platinum, diamond }

class GlowUpShareScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const GlowUpShareScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<GlowUpShareScreen> createState() => _GlowUpShareScreenState();
}

class _GlowUpShareScreenState extends ConsumerState<GlowUpShareScreen> {
  final GlobalKey _shareKey = GlobalKey();
  bool _isCapturing = false;
  bool _isSharing = false;
  bool _isDownloading = false;
  late PageController _pageController;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleShareOrDownload(bool isDownload) async {
    setState(() {
      _isCapturing = true;
      if (isDownload) {
        _isDownloading = true;
      } else {
        _isSharing = true;
      }
    });
    await Future.delayed(const Duration(milliseconds: 300));

    final bytes = await ViralShareService.captureWidget(_shareKey);
    setState(() {
      _isCapturing = false;
      _isSharing = false;
      _isDownloading = false;
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
  }

  CardTier _getCardTier(double aura) {
    if (aura >= 90) return CardTier.diamond;
    if (aura >= 85) return CardTier.gold;
    if (aura >= 80) return CardTier.platinum;
    return CardTier.silver;
  }

  Color _getAccentColor(CardTier tier) {
    switch (tier) {
      case CardTier.diamond: return const Color(0xFF00E5FF);
      case CardTier.gold: return const Color(0xFFFFD700);
      case CardTier.platinum: return const Color(0xFFE5E4E2);
      case CardTier.silver: return const Color(0xFFA9A9A9);
    }
  }

  LinearGradient _getCardGradient(CardTier tier) {
    switch (tier) {
      case CardTier.diamond:
        return const LinearGradient(
          colors: [Color(0xCC0B192C), Color(0xCC1A3B5C), Color(0xCC0B192C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case CardTier.gold:
        return const LinearGradient(
          colors: [Color(0xCC2A1C00), Color(0xCC4A3500), Color(0xCC2A1C00)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case CardTier.platinum:
        return const LinearGradient(
          colors: [Color(0xCC1E1E1E), Color(0xCC3A3A3A), Color(0xCC1E1E1E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case CardTier.silver:
        return const LinearGradient(
          colors: [Color(0xCC151515), Color(0xCC252525), Color(0xCC151515)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
    }
  }

  String _getTierName(CardTier tier) {
    switch (tier) {
      case CardTier.diamond: return "DIAMOND TIER";
      case CardTier.gold: return "GOLD TIER";
      case CardTier.platinum: return "PLATINUM TIER";
      case CardTier.silver: return "SILVER TIER";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStateProvider);
    final scans = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share Glow Up',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: scans.isEmpty
                ? Center(
                    child: Text(
                      'No scans available',
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxH = constraints.maxHeight - 32;
                      final maxW = constraints.maxWidth - 32;
                      
                      double h = maxH;
                      double w = h * 9 / 16;
                      if (w > maxW) {
                        w = maxW;
                        h = w * 16 / 9;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            key: _shareKey,
                            child: SizedBox(
                              width: w,
                              height: h,
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (idx) {
                                      setState(() {
                                        _currentPageIndex = idx;
                                      });
                                    },
                                    itemCount: scans.length,
                                    itemBuilder: (context, index) {
                                      final scan = scans[index];
                                      return Center(
                                        child: _buildCardContent(scan, user, index, scans.length, w, h),
                                      );
                                    },
                                  ),
                                  if (_isCapturing)
                                    Positioned(
                                      bottom: 24,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                            'assets/image/growup_ai_logo.png',
                                            height: 45,
                                            width: 45,
                                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (scans.length > 1)
                            Positioned(
                              bottom: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  scans.length,
                                  (idx) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPageIndex == idx
                                          ? Colors.white
                                          : Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _ActionButton(
                    text: 'Save',
                    icon: Icons.download_rounded,
                    isLoading: _isDownloading,
                    onTap: () => _handleShareOrDownload(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionButton(
                    text: 'Share',
                    icon: Icons.send_rounded,
                    isLoading: _isSharing,
                    onTap: () => _handleShareOrDownload(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(ScanRecord scan, UserState user, int index, int totalScans, double w, double h) {
    String headerText = index == 0 ? "Now" : scan.weekLabel(totalScans, index);
    final tier = _getCardTier(scan.auraScore);
    final accentColor = _getAccentColor(tier);

    final noseSymmetry = (scan.fullData?['nose_details']?['symmetry'] as num?)?.toDouble() ?? 80.0;
    final lipSymmetry = (scan.fullData?['lip_details']?['symmetry'] as num?)?.toDouble() ?? 80.0;
    final eyeAlertness = (scan.fullData?['eye_details']?['alertness'] as num?)?.toDouble() ?? scan.eyeScore;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: _getCardGradient(tier),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(50),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withAlpha(40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GROWUP AI',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withAlpha(80)),
                      ),
                      child: Text(
                        _getTierName(tier),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: scan.imageUrl != null && scan.imageUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(scan.imageUrl!),
                          backgroundColor: Colors.grey[800],
                        )
                      : CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[800],
                          child: Icon(Icons.person, size: 40, color: accentColor),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  headerText,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                
                const Spacer(flex: 1),
                
                Column(
                  children: [
                    Text(
                      scan.auraScore.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: accentColor.withAlpha(150),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AURA SCORE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        color: accentColor,
                        shadows: [
                          Shadow(
                            color: accentColor.withAlpha(100),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildExtraChip('Face Shape', scan.faceShape, accentColor),
                    const SizedBox(width: 12),
                    _buildExtraChip('Est. Age', '${scan.faceAgeEstimation} yrs', accentColor),
                  ],
                ),
                
                const Spacer(flex: 1),
                const Divider(color: Colors.white24, thickness: 1),
                const Spacer(flex: 1),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactStat('Eyes', eyeAlertness, accentColor),
                          const SizedBox(height: 16),
                          _buildCompactStat('Nose', noseSymmetry, accentColor),
                          const SizedBox(height: 16),
                          _buildCompactStat('Jawline', scan.jawlineScore, accentColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactStat('Skin', scan.skinScore, accentColor),
                          const SizedBox(height: 16),
                          _buildCompactStat('Lips', lipSymmetry, accentColor),
                          const SizedBox(height: 16),
                          _buildCompactStat('Symmetry', scan.faceSymmetry, accentColor),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (_isCapturing) 
                  const SizedBox(height: 60)
                else 
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraChip(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, double value, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              value.toInt().toString(),
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 14, // Big 3D bar
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(150),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * (value / 100),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withAlpha(180),
                          accentColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(120),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth * (value / 100),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(100),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
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
                  color: Colors.black,
                ),
              )
            else ...[
              Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.black, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
