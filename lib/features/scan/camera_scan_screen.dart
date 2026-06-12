import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import 'scanning_process_screen.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _faceDetected = false;
  bool _isCapturingState = false;
  double _captureProgress = 0.0;

  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _initializeCamera();
  }


  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();

        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });

        _cameraController!.startImageStream(_processCameraImage);
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    } else {
      debugPrint('Camera permission denied.');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isCapturingState) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        if (mounted) {
          setState(() {
            _faceDetected = faces.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    final InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _onCaptureTapped() async {
    if (_isCapturingState) return;

    if (!_faceDetected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please align your face first!', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isCapturingState = true;
      _captureProgress = 0.0;
    });

    // ── Animate 0 → 10%, then take picture immediately ───────────────────────
    String? finalPath;

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;

      if (!_faceDetected) {
        setState(() {
          _isCapturingState = false;
          _captureProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face moved! Please hold still.', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() => _captureProgress = i / 100.0);
    }

    // ── Take photo at 10% ────────────────────────────────────────────────────
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        final XFile rawFile = await _cameraController!.takePicture();
        final String? compressedPath = await _compressToWebP(rawFile.path);
        finalPath = compressedPath ?? rawFile.path;
      } catch (e) {
        debugPrint('Error taking picture: \$e');
      }
    }

    // ── Continue animating 10 → 100% (just UI, photo is already taken) ───────
    for (int i = 11; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 12));
      if (!mounted) return;
      setState(() => _captureProgress = i / 100.0);
    }

    // ── Navigate to scanning process screen ──────────────────────────────────
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanningProcessScreen(imagePath: finalPath),
        ),
      );
    }
  }

  /// Compress the captured image to WebP at 80% quality.
  Future<String?> _compressToWebP(String sourcePath) async {
    try {
      final targetPath = '${(await getTemporaryDirectory()).path}/aura_scan_${DateTime.now().millisecondsSinceEpoch}.webp';
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 80,
        format: CompressFormat.webp,
      );
      return result?.path;
    } catch (e) {
      debugPrint('Compression failed: \$e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Oval dimensions and position (center, slightly above middle)
    const ovalW = 300.0;
    const ovalH = 400.0;
    final ovalLeft = (screenSize.width - ovalW) / 2;
    final ovalTop = (screenSize.height - ovalH) / 2 - screenSize.height * 0.08;
    final ovalRect = Rect.fromLTWH(ovalLeft, ovalTop, ovalW, ovalH);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Full screen camera (always behind everything) ──────────────
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  // On Android the preview comes in landscape buffer; swap w/h
                  width: _cameraController!.value.previewSize?.height ?? screenSize.width,
                  height: _cameraController!.value.previewSize?.width ?? screenSize.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),

          // ── 2. Dark overlay with transparent oval hole ────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: OvalHolePainter(ovalRect: ovalRect),
            ),
          ),

          // ── 3. Glowing oval border + rotating spinner ────────────────────
          Positioned(
            left: ovalLeft - 12,
            top: ovalTop - 12,
            width: ovalW + 24,
            height: ovalH + 24,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (_, child) => CustomPaint(
                painter: OvalGlowPainter(
                  ovalW: ovalW,
                  ovalH: ovalH,
                  detected: _faceDetected,
                  spinProgress: _isCapturingState ? 1.0 : _rotationController.value,
                ),
              ),
            ),
          ),

          // ── 4. Progress arc when capturing ───────────────────────────────
          if (_isCapturingState)
            Positioned(
              left: ovalLeft,
              top: ovalTop,
              width: ovalW,
              height: ovalH,
              child: CustomPaint(
                painter: ProgressArcPainter(_captureProgress),
              ),
            ),

          // ── 5. Progress % text ─────────────────────────────────────────────
          if (_isCapturingState)
            Positioned(
              left: ovalLeft,
              top: ovalTop,
              width: ovalW,
              height: ovalH,
              child: Center(
                child: Text(
                  '${(_captureProgress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: AppTheme.success, blurRadius: 20),
                    ],
                  ),
                ),
              ),
            ),

          // ── 6. UI controls ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AI FACE SCAN',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _faceDetected
                                ? AppTheme.success.withAlpha(100)
                                : Colors.white10,
                          ),
                        ),
                        child: Text(
                          _faceDetected
                              ? 'Face Aligned ✓  Ready to scan'
                              : 'Align your face inside the glowing oval',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _faceDetected ? AppTheme.success : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom capture button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _onCaptureTapped,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _faceDetected ? AppTheme.success : Colors.white38,
                              width: 4,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _faceDetected
                                  ? const LinearGradient(
                                      colors: [AppTheme.success, Color(0xFF00B359)])
                                  : AppTheme.primaryGradient,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TAP TO SCAN CURRENT AURA',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══ Painters ═══════════════════════════════════════════════════════════════

/// Draws a semi-transparent dark overlay everywhere EXCEPT the oval hole.
class OvalHolePainter extends CustomPainter {
  final Rect ovalRect;
  OvalHolePainter({required this.ovalRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(195)
      ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(ovalRect, const Radius.circular(160)));

    path.fillType = PathFillType.evenOdd; // <-- punches the oval out
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OvalHolePainter oldDelegate) => oldDelegate.ovalRect != ovalRect;
}

/// Draws a crisp border + outer-only glow + rotating spinner arc around the oval.
/// The widget is placed 12px larger on each side so the glow blurs outward,
/// never bleeding into the transparent camera area.
class OvalGlowPainter extends CustomPainter {
  final double ovalW;
  final double ovalH;
  final bool detected;
  final double spinProgress;
  OvalGlowPainter({
    required this.ovalW,
    required this.ovalH,
    required this.detected,
    this.spinProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The oval is centred inside this canvas which is 24px wider/taller.
    final ovalRect = Rect.fromLTWH(12, 12, ovalW, ovalH);
    final rrect = RRect.fromRectAndRadius(ovalRect, const Radius.circular(160));

    final color = detected ? AppTheme.success : AppTheme.secondary;

    // 1. Outer glow (blurred)
    final glowPaint = Paint()
      ..color = color.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect, glowPaint);

    // 2. Dim base border
    final borderPaint = Paint()
      ..color = color.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    // 3. Rotating arc (~35% of perimeter)
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics[0];
    final totalLen = metric.length;
    const arcFraction = 0.35;
    final arcLen = totalLen * arcFraction;
    final startOffset = totalLen * spinProgress;

    // Draw the arc, wrapping around if needed
    final end = startOffset + arcLen;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0)
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * 3.14159,
        colors: [color.withAlpha(0), color, color.withAlpha(20)],
      ).createShader(ovalRect);

    if (end <= totalLen) {
      final arc = metric.extractPath(startOffset, end);
      canvas.drawPath(arc, arcPaint);
    } else {
      // Wrap: draw from startOffset to end, then 0 to overflow
      final arc1 = metric.extractPath(startOffset, totalLen);
      final arc2 = metric.extractPath(0, end - totalLen);
      canvas.drawPath(arc1, arcPaint);
      canvas.drawPath(arc2, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OvalGlowPainter old) =>
      old.detected != detected ||
      old.ovalW != ovalW ||
      old.ovalH != ovalH ||
      old.spinProgress != spinProgress;
}

/// Draws a glowing green progress arc that traces the oval border.
class ProgressArcPainter extends CustomPainter {
  final double progress;
  ProgressArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = AppTheme.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(160),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics[0];
    final arc = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(arc, paint);
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter old) => old.progress != progress;
}
