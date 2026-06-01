import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/face_analyzer_engine.dart';

class ScanDetailsPage extends StatefulWidget {
  final FaceAnalysisResult result;

  const ScanDetailsPage({super.key, required this.result});

  @override
  State<ScanDetailsPage> createState() => _ScanDetailsPageState();
}

class _ScanDetailsPageState extends State<ScanDetailsPage> {
  // GlobalKeys for sharing each card
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _symmetryKey = GlobalKey();
  final GlobalKey _faceEyesKey = GlobalKey();
  final GlobalKey _noseLipsKey = GlobalKey();
  final GlobalKey _skinGeneticsKey = GlobalKey();

  Future<void> _captureAndShareCard(GlobalKey key, String cardTitle) async {
    try {
      // 1. Capture the widget as an image
      RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/growup_analysis_${cardTitle.toLowerCase().replaceAll(' ', '_')}.png').create();
      await file.writeAsBytes(pngBytes);

      // 3. Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my $cardTitle analysis on GrowUp AI! 🎯 #Looksmaxxing #FaceAnalysis',
      );
    } catch (e) {
      debugPrint('Error sharing card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate share image. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FULL ANALYSIS',
          style: AppTypography.titleMedium.copyWith(color: Colors.white, letterSpacing: 2),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 12),
            
            // 1. OVERVIEW SECTION
            RepaintBoundary(
              key: _overviewKey,
              child: _buildCategoryCard(
                icon: "📊",
                title: "Overview",
                onShare: () => _captureAndShareCard(_overviewKey, "Overview"),
                metrics: [
                  _MetricItem("🏆", "Model Potential", widget.result.modelPotential),
                  _MetricItem("🔥", "Hot Score", widget.result.hotScore),
                  _MetricItem("💎", "Beauty Tier", widget.result.attractivenessScore),
                  _MetricItem("✨", "Skin Quality", widget.result.skinSmooth),
                  _MetricItem("💪", "Masculinity", widget.result.masculinityScore),
                  _MetricItem("💃", "Femininity", widget.result.femininityScore),
                ],
                infos: [
                  _InfoRow("Face Shape", widget.result.faceShape),
                  _InfoRow("Global Rank", "Top ${widget.result.globalRanking}%"),
                  _InfoRow("Category", widget.result.attractivenessRating),
                ],
              ),
            ),

            // 2. SYMMETRY & HARMONY
            RepaintBoundary(
              key: _symmetryKey,
              child: _buildCategoryCard(
                icon: "⚖️",
                title: "Symmetry & Harmony",
                onShare: () => _captureAndShareCard(_symmetryKey, "Symmetry"),
                metrics: [
                  _MetricItem("⚖️", "Overall Symmetry", widget.result.overallSymmetry),
                  _MetricItem("↔️", "Horizontal Sym", widget.result.horizontalSymmetry),
                  _MetricItem("↕️", "Vertical Sym", widget.result.verticalSymmetry),
                  _MetricItem("✕", "Diagonal Sym", widget.result.diagonalSymmetry),
                  _MetricItem("📐", "Golden Ratio", widget.result.goldenRatioScore),
                  _MetricItem("🎵", "Harmony Score", widget.result.harmonyScore),
                ],
                infos: [
                  _InfoRow("L:W Ratio", "${widget.result.faceLengthToWidthRatio.toStringAsFixed(2)} : 1"),
                  _InfoRow("Lookalike", widget.result.celebrityMatch),
                  _InfoRow("Posture", "Balanced"),
                ],
              ),
            ),

            // 3. FACE & EYES
            RepaintBoundary(
              key: _faceEyesKey,
              child: _buildCategoryCard(
                icon: "👁️",
                title: "Face & Eyes",
                onShare: () => _captureAndShareCard(_faceEyesKey, "Face and Eyes"),
                metrics: [
                  _MetricItem("💠", "Shape Score", widget.result.faceShapeScore),
                  _MetricItem("👁️", "Eye Size", widget.result.eyeSize),
                  _MetricItem("📐", "Eye Symmetry", widget.result.eyeSymmetry),
                  _MetricItem("📏", "Eye Spacing", widget.result.eyeSpacing),
                  _MetricItem("🌿", "Brow Arch", widget.result.eyebrowArch),
                  _MetricItem("📏", "Brow Thick", widget.result.eyebrowThickness),
                ],
                infos: [
                  _InfoRow("Gonial Angle", "${widget.result.gonialAngle.toStringAsFixed(1)}°"),
                  _InfoRow("Mandibular", "${widget.result.mandibularAngle.toStringAsFixed(1)}°"),
                  _InfoRow("Eye Feature", "Balanced"),
                ],
              ),
            ),

            // 4. NOSE & LIPS
            RepaintBoundary(
              key: _noseLipsKey,
              child: _buildCategoryCard(
                icon: "👃",
                title: "Nose & Lips",
                onShare: () => _captureAndShareCard(_noseLipsKey, "Nose and Lips"),
                metrics: [
                  _MetricItem("👃", "Nose Symmetry", widget.result.nostrilSymmetry),
                  _MetricItem("↔️", "Nose Width", widget.result.noseWidth),
                  _MetricItem("↕️", "Nose Length", widget.result.noseLength),
                  _MetricItem("💋", "Lip Thickness", widget.result.lipThickness),
                  _MetricItem("⚖️", "Lip Symmetry", widget.result.lipSymmetry),
                  _MetricItem("😊", "Smile Intensity", widget.result.smileIntensity),
                ],
                infos: [
                  _InfoRow("Lip Shape", widget.result.lipShape),
                  _InfoRow("Nose Angle", "${widget.result.nasolabialAngle.toStringAsFixed(1)}°"),
                  _InfoRow("Lip Ratio", "${widget.result.lipRatio.toStringAsFixed(1)} : 1"),
                ],
              ),
            ),

            // 5. SKIN, AGE & GENETICS
            RepaintBoundary(
              key: _skinGeneticsKey,
              child: _buildCategoryCard(
                icon: "✨",
                title: "Skin & Genetics",
                onShare: () => _captureAndShareCard(_skinGeneticsKey, "Genetics"),
                metrics: [
                  _MetricItem("✨", "Skin Smoothness", widget.result.skinSmooth),
                  _MetricItem("🔬", "Skin Texture", widget.result.skinTexture),
                  _MetricItem("🎨", "Skin Tone", widget.result.skinTone),
                  _MetricItem("🔍", "Face Clarity", widget.result.faceClarity),
                  _MetricItem("🌟", "Youthfulness", widget.result.youthfulnessScore),
                  _MetricItem("🧬", "Eth. Confidence", widget.result.ethnicityConfidence),
                ],
                infos: [
                  _InfoRow("Estimated Age", "${widget.result.estimatedAge} years"),
                  _InfoRow("Emotion", widget.result.dominantEmotion),
                  _InfoRow("Primary Origin", widget.result.primaryEthnicity),
                ],
                customContent: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "🌍 GENETIC BREAKDOWN",
                      style: AppTypography.labelSmall.copyWith(color: Colors.white54, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    ...widget.result.ethnicityBreakdown.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.ethnicity, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text("${e.percentage.toInt()}%", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String icon,
    required String title,
    required List<_MetricItem> metrics,
    required List<_InfoRow> infos,
    required VoidCallback onShare,
    Widget? customContent,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Text(
                    title.toUpperCase(),
                    style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, color: AppColors.primary, size: 20),
                tooltip: 'Share Card',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Metrics Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) => metrics[index].build(),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          
          // Basic Info Table
          ...infos.map((info) => info.build()),
          
          customContent ?? const SizedBox.shrink(),
          
          // Branding Watermark (Optional but requested vibe)
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "GROWUP AI",
              style: AppTypography.labelSmall.copyWith(color: Colors.white10, fontSize: 8, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final String icon;
  final String label;
  final double value;

  _MetricItem(this.icon, this.label, this.value);

  Widget build() {
    Color barColor = const Color(0xFF00FF0A);
    if (value < 60) {
      barColor = Colors.redAccent;
    } else if (value < 80) {
      barColor = Colors.orangeAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "${value.toInt()}",
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: (value / 100).clamp(0.05, 1.0),
            child: Container(
              decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow(this.label, this.value);

  Widget build() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
