import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';

class HairStyleImageFullscreen extends StatefulWidget {
  final String? imageBase64;
  final String? imageUrl;

  const HairStyleImageFullscreen({
    super.key,
    this.imageBase64,
    this.imageUrl,
  }) : assert(imageBase64 != null || imageUrl != null,
            'Either imageBase64 or imageUrl must be provided');

  @override
  State<HairStyleImageFullscreen> createState() => _HairStyleImageFullscreenState();
}

class _HairStyleImageFullscreenState extends State<HairStyleImageFullscreen>
    with SingleTickerProviderStateMixin {
  late Uint8List? _imageBytes;
  bool _isNetworkMode = false;
  bool _isProcessing = false;
  bool _controlsVisible = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null) {
      _isNetworkMode = true;
      _imageBytes = null;
    } else {
      _isNetworkMode = false;
      _imageBytes = base64Decode(widget.imageBase64!);
    }
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  /// Composites GrowUp-AI logo watermark onto the image at bottom-right.
  Future<Uint8List> _addWatermark(Uint8List imageBytes) async {
    // Decode main image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final mainImage = frame.image;

    // Load and scale logo
    final logoData = await rootBundle.load('assets/image/growup_ai_logo.png');
    final logoBytes = logoData.buffer.asUint8List();
    final logoTargetWidth = (mainImage.width * 0.18).round().clamp(80, 200);
    final logoCodec = await ui.instantiateImageCodec(
      logoBytes,
      targetWidth: logoTargetWidth,
    );
    final logoFrame = await logoCodec.getNextFrame();
    final logo = logoFrame.image;

    // Composite on canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw main image
    canvas.drawImage(mainImage, Offset.zero, Paint());

    // Position logo at bottom-right with 24px margin
    const margin = 24.0;
    const padding = 10.0;
    final logoX = mainImage.width.toDouble() - logo.width.toDouble() - margin;
    final logoY = mainImage.height.toDouble() - logo.height.toDouble() - margin;

    // Dark pill behind logo for readability
    final bgPaint = Paint()
      ..color = const Color(0xAA000000)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          logoX - padding,
          logoY - padding,
          logo.width.toDouble() + padding * 2,
          logo.height.toDouble() + padding * 2,
        ),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // Draw logo
    canvas.drawImage(logo, Offset(logoX, logoY), Paint());

    final picture = recorder.endRecording();
    final composited = await picture.toImage(mainImage.width, mainImage.height);
    final byteData = await composited.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Fetches image bytes (handles both memory and network).
  Future<Uint8List> _getImageBytes() async {
    if (!_isNetworkMode && _imageBytes != null) return _imageBytes!;
    // Fetch network image
    final uri = Uri.parse(widget.imageUrl!);
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(uri);
    final response = await request.close();
    final bytes = <int>[];
    await response.forEach(bytes.addAll);
    return Uint8List.fromList(bytes);
  }

  Future<void> _downloadImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _getImageBytes();
      final watermarked = await _addWatermark(bytes);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/growup_hairstyle_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(watermarked);
      await Gal.putImage(tempPath);
      
      if (!mounted) return;
      _showSnack(
        '✅ Saved to Gallery!',
        AppTheme.primaryDark,
      );
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _getImageBytes();
      final watermarked = await _addWatermark(bytes);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/growup_hairstyle_share.png');
      await tempFile.writeAsBytes(watermarked);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: '✂️ My AI Hairstyle Match Report from GrowUp-AI!\n\nDiscover your perfect hairstyle with AI at GrowUp-AI.',
      );
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          'AI Hairstyle Report',
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable image
              InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.8,
                maxScale: 6.0,
                child: Center(
                  child: _isNetworkMode
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (ctx, e, st) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white38, size: 64),
                          ),
                        )
                      : Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                ),
              ),

              // Bottom controls bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                bottom: _controlsVisible ? 0 : -140,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                  child: _isProcessing
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Adding watermark...',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.download_rounded,
                                label: 'Save to Gallery',
                                color: AppTheme.primary,
                                onTap: _downloadImage,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.share_rounded,
                                label: 'Share',
                                color: AppTheme.secondary,
                                onTap: _shareImage,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Tap hint overlay — visible briefly on first load
              if (_controlsVisible)
                Positioned(
                  bottom: 130,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Tap image to hide/show controls',
                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
