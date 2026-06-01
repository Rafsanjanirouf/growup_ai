import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bottom_action_button.dart';
import '../../shared/widgets/premium_dialog.dart';
import '../../shared/widgets/voice_guide_toggle.dart';
import '../../core/providers/voice_guide_provider.dart';
import '../../main.dart';
import 'analyzing_scan_screen.dart';

class FaceScanScreen extends ConsumerStatefulWidget {
  const FaceScanScreen({super.key});

  @override
  ConsumerState<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends ConsumerState<FaceScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isFaceDetected = false;
  bool _isBusy = false;
  bool _hasImageFormatError = false; // Flag to stop console spam

  // ML Kit Face Detector
  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize Face Detector with Landmark mode
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    // Trigger AI Guide narration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(voiceGuideProvider.notifier)
          .speak(
            "Let's capture your features. Position your face within the frame and ensure good lighting for the best results.",
          );
    });

    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for face scan'),
          ),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21 // Prefer NV21 for ML Kit on Android
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint('NV21 not supported, falling back to YUV420: $e');
      _cameraController = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });

      // Start live face detection stream
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    if (controller != null) {
      _cameraController = null; // Nullify immediately to stop callbacks
      if (controller.value.isInitialized) {
        try {
          if (controller.value.isStreamingImages) {
            await controller.stopImageStream();
          }
          await controller.dispose();
        } catch (e) {
          debugPrint('Error stopping camera: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _stopCamera(); // Fire and forget but safe
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!mounted || _isBusy || _isCapturing || _cameraController == null) {
      return;
    }

    // Stop processing if we've already logged a fatal format error to avoid spam
    if (_hasImageFormatError) {
      return;
    }

    _isBusy = true;

    try {
      final camera = _cameraController;
      if (camera == null) return;

      final sensorOrientation = camera.description.sensorOrientation;
      final InputImageRotation rotation = _rotationFromInt(sensorOrientation);
      
      // Determine format
      final InputImageFormat format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

      final plane = image.planes.first;

      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        final hasFace = faces.isNotEmpty;
        if (_isFaceDetected != hasFace) {
          setState(() {
            _isFaceDetected = hasFace;
          });
        }
      }
    } catch (e) {
      if (!_hasImageFormatError) {
        debugPrint('Error processing camera image: $e');
        // If it's a persistent format error, flag it to stop logs
        if (e.toString().contains('InputImageConverterError') ||
            e.toString().contains('ImageFormat is not supported')) {
          _hasImageFormatError = true;
          debugPrint(
            '⚠️ Camera image format mismatch detected. Face detection stream suspended to prevent console spam.',
          );
        }
      }
    } finally {
      _isBusy = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageRotation _rotationFromInt(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();

      if (!mounted) {
        return;
      }

      // Create InputImage for ML Kit
      final inputImage = InputImage.fromFilePath(image.path);

      // Process face detection
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      // Validation logic
      if (faces.isEmpty) {
        _showErrorDialog(
          title: 'No Face Detected',
          message:
              'We couldn\'t find a face in the frame. Please ensure you are in a well-lit area and looking directly at the camera.',
        );
        setState(() => _isCapturing = false);
        return;
      }

      if (faces.length > 1) {
        _showErrorDialog(
          title: 'Multiple Faces',
          message:
              'Please ensure only one person is in the frame for an accurate face scan.',
        );
        setState(() => _isCapturing = false);
        return;
      }

      // Successful capture - stop camera first then navigate
      final navigator = Navigator.of(context);
      await _stopCamera();

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => AnalyzingScanScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint('Error during face scan: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => PremiumDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-screen Camera Feed
          _buildMainCameraContent(),

          // 2. Premium HUD Overlay
          _buildScanOverlays(),

          // 3. Top Status Area
          _buildTopStatusArea(),

          // 4. Bottom Control Area
          _buildBottomControlArea(),

          // 5. Voice Toggle
          const VoiceGuideToggle(),
        ],
      ),
    );
  }

  Widget _buildMainCameraContent() {
    return Positioned.fill(
      child: _isCameraInitialized && _cameraController != null
          ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            )
          : Container(
              color: AppColors.surfaceLowest,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
    );
  }

  Widget _buildTopStatusArea() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildFloatingBackButton(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FACE SCAN',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI ENGINE ACTIVE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlays() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanning HUD Frame
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 1.1,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFaceDetected
                    ? AppColors.secondary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
          ),

          // Face Oval Helper
          Container(
            width: 280,
            height: 380,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFaceDetected ? AppColors.primary : Colors.white24,
                width: 2,
              ),
              borderRadius: BorderRadius.all(Radius.elliptical(140, 190)),
              boxShadow: _isFaceDetected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),

          // Active Scanning Line
          _buildScanningLine(),

          // Feature Scan Points (Mocking dynamic dots if face is detected)
          if (_isFaceDetected) ...[
            _buildScanDot(top: 250, left: 100),
            _buildScanDot(top: 250, right: 100),
            _buildScanDot(top: 350, left: 180),
            _buildScanDot(top: 450, left: 120),
            _buildScanDot(top: 450, right: 120),
          ],
        ],
      ),
    );
  }

  Widget _buildScanDot({
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildBottomControlArea() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 40,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isFaceDetected)
                _buildDetectionStatus()
              else
                _buildInstructionText(),
              const SizedBox(height: 32),
              BottomActionButton(
                label: _isCapturing
                    ? 'ANALYZING...'
                    : (_isFaceDetected ? 'START SCAN' : 'WAITING FOR FACE...'),
                icon: Icons.face_retouching_natural_rounded,
                isLoading: _isCapturing,
                onTap: (_isFaceDetected && !_isCapturing)
                    ? _captureAndScan
                    : null,
              ),
              const SizedBox(height: 16),
              _buildSecondaryControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.secondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'FACE SECURED • READY TO ANALYZE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    return Text(
      'POSITION YOUR FACE WITHIN THE FRAME',
      style: AppTypography.labelSmall.copyWith(
        color: Colors.white.withValues(alpha: 0.6),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSecondaryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Positioned(
          top: 150 + (_scanController.value * 300),
          left: 60,
          right: 60,
          child: Opacity(
            opacity: _isFaceDetected ? 1.0 : 0.4,
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.secondary.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // "Scanning" tag following the line
                if (_isFaceDetected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SCANNING...',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBackButton() {
    return IconButton(
      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
      onPressed: () async {
        final navigator = Navigator.of(context);
        await _stopCamera();
        navigator.pop();
      },
    );
  }
}
