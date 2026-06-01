import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/face_analyzer_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'scan_details_page.dart';

class ScanReportPage extends StatefulWidget {
  final FaceAnalysisResult result;
  final String imagePath;
  final bool isHistory;

  const ScanReportPage({
    super.key,
    required this.result,
    required this.imagePath,
    this.isHistory = false,
  });

  @override
  State<ScanReportPage> createState() => _ScanReportPageState();
}

class _ScanReportPageState extends State<ScanReportPage> {
  bool _isRatingView = true;
  final GlobalKey _shareKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _captureAndShareReport() async {
    setState(() => _isSharing = true);
    
    // Small delay to allow UI to update (removing buttons)
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      RenderRepaintBoundary? boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/growup_report_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My GrowUp AI Face Analysis Results! 🎯 #Looksmaxxing #FaceRating',
      );
    } catch (e) {
      debugPrint('Error sharing report: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallScore = widget.result.attractivenessScore.toInt();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
             // Scrollable Content
             SingleChildScrollView(
               physics: const BouncingScrollPhysics(),
               padding: const EdgeInsets.only(bottom: 120),
               child: Column(
                 children: [
                    // 1. Header (Part of shared image)
                    RepaintBoundary(
                      key: _shareKey,
                      child: Container(
                        color: Colors.black, // Ensure background is solid for share
                        child: Column(
                          children: [
                            _buildHeader(context),
                            
                            const SizedBox(height: 16),
                            
                            // 3. Single Hero Image
                            _buildMotivationalHero(),
                            
                            const SizedBox(height: 24),
                            
                            // 4. Metrics Grid
                            _buildMetricsGrid(),

                            if (_isSharing) ...[
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  "GROWUP AI",
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white24,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    if (!_isSharing) ...[
                      const SizedBox(height: 24),
                      // 2. Segmented Control (Hidden during share)
                      _buildSegmentedControl(),
                    ],
                 ],
               ),
             ),
             
             // 5. Sticky Bottom Action Bar
             _buildBottomActionBar(overallScore),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Show a historical date if it's a history item, otherwise Today
    final dateStr = widget.isHistory ? "Saved Report" : DateFormat('yyyy/MM/dd').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Left Spacer (to balance the close button on the right)
          const SizedBox(width: 48),
          
          // Center Title and Date
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Results',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Close button on right (Hidden during share)
          SizedBox(
            width: 48,
            child: _isSharing 
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentTab(
                label: 'Rating',
                isActive: _isRatingView,
                onTap: () => setState(() => _isRatingView = true),
              ),
            ),
            Expanded(
              child: _SegmentTab(
                label: 'Full analysis',
                isActive: !_isRatingView,
                onTap: () {
                   // Navigate to Full Analysis Screen immediately as requested
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => ScanDetailsPage(result: widget.result)),
                   );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalHero() {
    final currentScore = widget.result.attractivenessScore.toInt();
    final potentialTarget = 95;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left Side: Face Image with Side Fade
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                    SizedBox.expand(
                      child: widget.imagePath.startsWith('http') 
                        ? Image.network(widget.imagePath, fit: BoxFit.cover)
                        : widget.imagePath.isEmpty
                          ? const Center(child: Icon(Icons.face, size: 80, color: Colors.white10))
                          : Image.file(File(widget.imagePath), fit: BoxFit.cover),
                    ),
                   // Dual Fade Gradient (Bottom and Right)
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.centerLeft,
                         end: Alignment.centerRight,
                         colors: [
                           Colors.transparent,
                           const Color(0xFF161616).withValues(alpha: 0.2),
                           const Color(0xFF161616),
                         ],
                         stops: const [0.0, 0.7, 1.0],
                       ),
                     ),
                   ),
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [
                           Colors.transparent,
                           const Color(0xFF161616).withValues(alpha: 0.5),
                           const Color(0xFF161616),
                         ],
                         stops: const [0.6, 0.9, 1.0],
                       ),
                     ),
                   ),
                ],
              ),
            ),

            // Right Side: Potential Dashboard
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GROWTH POTENTIAL",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Current -> Potential Logic
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CURRENT", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("$currentScore", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 24),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TARGET", style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: currentScore.toDouble(), end: potentialTarget.toDouble()),
                              duration: const Duration(seconds: 2),
                              builder: (context, value, child) {
                                return Text("${value.toInt()}", style: const TextStyle(color: AppColors.secondary, fontSize: 42, fontWeight: FontWeight.w900));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Progress to Potential
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5)),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (potentialTarget / 100).clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF1E5AFF), Color(0xFF00FF0A)]),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // The Roadmap Markers (+2, +5, +4)
                    _buildPathItem("+2", "Skin Texture"),
                    const SizedBox(height: 12),
                    _buildPathItem("+5", "Jawline Definition"),
                    const SizedBox(height: 12),
                    _buildPathItem("+4", "Eye Symmetry"),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathItem(String gain, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            gain,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final res = widget.result;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildDarkCard('Overall', res.attractivenessScore.toInt()),
          _buildDarkCard('Masculinity', res.masculinityScore.toInt()),
          _buildDarkCard('Jawline', res.overallSymmetry.toInt()),
          _buildDarkCard('Cheekbones', res.cheekboneScore.toInt()),
          _buildDarkCard('Skin Quality', res.skinSmooth.toInt()),
          _buildDarkCard('Attraction', res.modelPotential.toInt()), 
        ],
      ),
    );
  }

  Widget _buildDarkCard(String label, int score) {
    Color barColor;
    if (score >= 80) {
      barColor = const Color(0xFF00FF0A);
    } else if (score >= 60) {
      barColor = const Color(0xFFFFCC00);
    } else {
      barColor = const Color(0xFFFF3B30);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '$score',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
          Container(
            height: 10, // Enhanced thickness as requested
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (score / 100).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(int score) {
    return Positioned(
       bottom: 24,
       left: 20,
       right: 20,
       child: Row(
         children: [
           // Social Icons row
           _buildSocialIcon(Icons.message, const Color(0xFF25D366), onTap: _captureAndShareReport), // WhatsApp
           const SizedBox(width: 8),
           _buildSocialIcon(Icons.camera_alt, const Color(0xFFE1306C), onTap: _captureAndShareReport), // Instagram
           const SizedBox(width: 8),
           _buildSocialIcon(Icons.share_rounded, Colors.white12, onTap: _captureAndShareReport),
           
           const SizedBox(width: 12),
           
           // Main Share Button
           Expanded(
             child: SizedBox(
               height: 56,
               child: ElevatedButton(
                 onPressed: _captureAndShareReport,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF1E5AFF),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 0,
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(
                       'Share',
                       style: AppTypography.ctaButton.copyWith(color: Colors.white, fontSize: 18),
                     ),
                     const SizedBox(width: 8),
                     const Icon(Icons.reply_rounded, color: Colors.white, size: 20),
                   ],
                 ),
               ),
             ),
           ),
         ],
       ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color == Colors.white12 ? Colors.white70 : color, size: 24),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isActive ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
