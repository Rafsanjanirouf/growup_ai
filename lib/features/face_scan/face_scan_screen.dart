import 'dart:async';
import 'dart:ui';
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

class _FaceScanScreenState extends ConsumerState<FaceScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isFaceDetected = false;
  bool _isBusy = false;

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
      ref.read(voiceGuideProvider.notifier).speak(
        "Let's capture your features. Position your face within the frame and ensure good lighting for the best results."
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
          const SnackBar(content: Text('Camera permission is required for face scan')),
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
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        
        // Start live face detection stream
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
      } catch (e) {
        debugPrint('Error stopping camera: $e');
      } finally {
        _cameraController = null;
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
    if (!mounted || _isBusy || _isCapturing || _cameraController == null) return;
    _isBusy = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController;
      if (camera == null) return;
      
      final sensorOrientation = camera.description.sensorOrientation;
      
      final InputImageRotation rotation = _rotationFromInt(sensorOrientation);
      final InputImageFormat format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
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
      debugPrint('Error processing camera image: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImageRotation _rotationFromInt(int rotation) {
    switch (rotation) {
      case 0: return InputImageRotation.rotation0deg;
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      if (!mounted) return;

      // Create InputImage for ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      
      // Process face detection
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      // Validation logic
      if (faces.isEmpty) {
        _showErrorDialog(
          title: 'No Face Detected',
          message: 'We couldn\'t find a face in the frame. Please ensure you are in a well-lit area and looking directly at the camera.',
        );
        setState(() => _isCapturing = false);
        return;
      }

      if (faces.length > 1) {
        _showErrorDialog(
          title: 'Multiple Faces',
          message: 'Please ensure only one person is in the frame for an accurate biometric scan.',
        );
        setState(() => _isCapturing = false);
        return;
      }

      // Successful capture - stop camera first then navigate
      final navigator = Navigator.of(context);
      await _stopCamera();
      
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => AnalyzingScanScreen(
            imagePath: image.path,
          ),
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
      builder: (context) => PremiumDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Feed / Main Content
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 500),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: _buildCameraViewFinder(),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 2. Info Section (Responsive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildScanCounter(),
                      const SizedBox(height: 20),
                      _buildLightingTip(),
                    ],
                  ),
                ),
              ],
            ),
            
            // 3. Floating Header Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFloatingBackButton(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FACE SCAN',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'STEP 1 / 2',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // 4. Bottom Capture Area
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Updating/Processing status
                  if (_isCapturing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'UPDATING FACE DATA...',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isCapturing ? null : () {
                          setState(() => _isFaceDetected = false);
                        },
                        child: Text(
                          'RETAKE',
                          style: AppTypography.labelSmall.copyWith(
                            color: _isCapturing ? Colors.white24 : Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _stopCamera();
                          navigator.pushReplacementNamed('/main-navigation');
                        },
                        child: Text(
                          'SKIP FOR NOW',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BottomActionButton(
                    label: _isCapturing ? 'ANALYZING...' : (_isFaceDetected ? 'CAPTURE FACE' : 'POSITION YOUR FACE'),
                    icon: Icons.camera_enhance_rounded,
                    isLoading: _isCapturing,
                    loadingText: 'PROCESSING...',
                    onTap: (_isFaceDetected && !_isCapturing) ? _captureAndScan : null,
                  ),
                ],
              ),
            ),
            const VoiceGuideToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraViewFinder() {
    return Stack(
      children: [
        // Viewfinder Corners
        _buildCorner(top: -4, left: -4, isSecondary: true),
        _buildCorner(bottom: -4, right: -4, isSecondary: false),
        
        // Inner Container
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.scrimDark.withValues(alpha: 0.8),
                blurRadius: 30,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isCameraInitialized && _cameraController != null)
                CameraPreview(_cameraController!)
              else
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),

              // Biometric HUD
              _buildBiometricHUD(),
              
              // Scanning Line Overlay
              _buildScanningLine(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({double? top, double? left, double? bottom, double? right, required bool isSecondary}) {
    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? BorderSide(color: isSecondary ? AppColors.secondary : AppColors.primary, width: 4) : BorderSide.none,
            left: left != null ? BorderSide(color: isSecondary ? AppColors.secondary : AppColors.primary, width: 4) : BorderSide.none,
            bottom: bottom != null ? BorderSide(color: isSecondary ? AppColors.secondary : AppColors.primary, width: 4) : BorderSide.none,
            right: right != null ? BorderSide(color: isSecondary ? AppColors.secondary : AppColors.primary, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top != null && left != null ? const Radius.circular(16) : Radius.zero,
            bottomRight: bottom != null && right != null ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricHUD() {
    return Stack(
      children: [
        Center(
          child: Stack(
            children: [
              // Outer Circle (Face mask outline)
              Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isFaceDetected 
                        ? AppColors.primary.withValues(alpha: 0.8) 
                        : Colors.white.withValues(alpha: 0.1), 
                    width: _isFaceDetected ? 3 : 1
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFaceDetected 
                          ? AppColors.primary.withValues(alpha: 0.3) 
                          : AppColors.primary.withValues(alpha: 0.05), 
                      spreadRadius: _isFaceDetected ? 30 : 20, 
                      blurRadius: 40
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Face mask gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _isFaceDetected 
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.02),
                            _isFaceDetected 
                              ? AppColors.secondary.withValues(alpha: 0.04)
                              : Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Face landmarks visualization
                    if (_isFaceDetected) ...[
                      // Left Eye
                      Positioned(
                        top: 80,
                        left: 75,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondary, width: 2),
                            boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 8)],
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right Eye
                      Positioned(
                        top: 80,
                        right: 75,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondary, width: 2),
                            boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 8)],
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Nose
                      Positioned(
                        top: 110,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 3,
                                height: 25,
                                color: AppColors.tertiary.withValues(alpha: 0.8),
                              ),
                              Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.tertiary.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Mouth
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Landmark dots (legacy, integrated into face mask above)
        if (!_isFaceDetected) ...[
          const Positioned(top: 150, left: 100, child: _LandmarkDot()),
          const Positioned(top: 150, right: 100, child: _LandmarkDot()),
          const Positioned(top: 200, left: 147, child: _LandmarkDot()),
          const Positioned(top: 260, left: 110, child: _LandmarkDot()),
          const Positioned(top: 260, right: 110, child: _LandmarkDot()),
        ],
      ],
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Positioned(
          top: 100 + (_scanController.value * 250),
          left: 40,
          right: 40,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.primary, Colors.transparent],
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _stopCamera();
              navigator.pushReplacementNamed('/goals');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScanCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bolt, color: AppColors.tertiary, size: 16),
          SizedBox(width: 8),
          Text('INITIAL SCAN', style: TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLightingTip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.light_mode_outlined, color: AppColors.secondary, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lighting Tip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Avoid shadows for highest accuracy.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandmarkDot extends StatelessWidget {
  const _LandmarkDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4, height: 4,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: AppColors.secondary, blurRadius: 8)],
      ),
    );
  }
}
