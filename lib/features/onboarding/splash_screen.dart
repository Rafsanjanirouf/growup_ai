import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  bool _isVideoInitialized = false;
  bool _isVideoComplete = false;
  bool _isTextComplete = false;
  bool _useVideoFallback = false;
  int _displayedCharactersTotal = 0;
  Timer? _typingTimer;
  Timer? _videoTimeoutTimer;

  final List<TextSpanData> _welcomeSpans = [
    TextSpanData(text: "Precision Analysis. ", color: Colors.white),
    TextSpanData(
      text: "Advanced Tracking. ",
      color: AppColors.primary,
      isBold: true,
    ),
    TextSpanData(text: "Experience the ", color: Colors.white),
    TextSpanData(
      text: "Ultimate Transformation",
      color: AppColors.secondary,
      isBold: true,
    ),
  ];

  late final int _totalCharacters;
  final int _typingDuration = 3000;
  final int _videoTimeoutMs = 10000;

  late DateTime _startTime;

  @override
  void initState() {
    super.initState();

    _totalCharacters = _welcomeSpans.fold(
      0,
      (sum, span) => sum + span.text.length,
    );
    _startTime = DateTime.now();

    // Pulse animation for button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    // Opacity animation for text container
    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _opacityController,
      curve: Curves.easeIn,
    );
    _opacityController.forward();

    _startTypingAnimation();
    _initializeVideoWithTimeout();
  }

  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) {
        _typingTimer?.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
      final progress = (elapsed / _typingDuration).clamp(0.0, 1.0);
      final newCharacters = (progress * _totalCharacters).toInt();

      if (newCharacters != _displayedCharactersTotal &&
          newCharacters <= _totalCharacters) {
        setState(() {
          _displayedCharactersTotal = newCharacters;
        });
      }

      if (progress >= 1.0) {
        _typingTimer?.cancel();
        setState(() {
          _isTextComplete = true;
        });
        _checkIfShowButton();
      }
    });
  }

  void _initializeVideoWithTimeout() {
    _videoTimeoutTimer = Timer(Duration(milliseconds: _videoTimeoutMs), () {
      if (!_isVideoInitialized && mounted) {
        setState(() {
          _useVideoFallback = true;
          _isVideoComplete = true;
        });
        _checkIfShowButton();
      }
    });

    try {
      _videoController =
          VideoPlayerController.asset('assets/videos/splash_bg.mp4')
            ..initialize()
                .then((_) {
                  if (mounted && !_useVideoFallback) {
                    _videoTimeoutTimer?.cancel();
                    setState(() {
                      _isVideoInitialized = true;
                    });
                    _videoController.play();
                    _videoController.setLooping(false);
                    _videoController.addListener(_videoListener);
                  }
                })
                .catchError((e) {
                  _videoTimeoutTimer?.cancel();
                  if (mounted) {
                    setState(() {
                      _useVideoFallback = true;
                      _isVideoComplete = true;
                    });
                  }
                  _checkIfShowButton();
                });
    } catch (e) {
      _videoTimeoutTimer?.cancel();
      if (!_useVideoFallback) {
        setState(() {
          _useVideoFallback = true;
          _isVideoComplete = true;
        });
        _checkIfShowButton();
      }
    }
  }

  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration) {
      setState(() {
        _isVideoComplete = true;
      });
      _checkIfShowButton();
    }
  }

  void _checkIfShowButton() {
    if (_isTextComplete && _isVideoComplete) {
      _pulseController.repeat();
    }
  }

  void _navigateToNextPage() {
    HapticFeedback.mediumImpact();
    if (_isVideoInitialized) {
      _videoController.pause();
    }
    ref.read(isUserAuthenticatedProvider).whenData((isAuthenticated) {
      if (!mounted) return;
      if (isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/main-navigation');
      } else {
        Navigator.of(context).pushReplacementNamed('/discovery');
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _videoTimeoutTimer?.cancel();
    if (_isVideoInitialized) {
      _videoController.pause();
      _videoController.removeListener(_videoListener);
      _videoController.dispose();
    }
    _pulseController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  List<TextSpan> _buildAnimatedSpans() {
    List<TextSpan> visibleSpans = [];
    int remainingChars = _displayedCharactersTotal;

    for (var spanData in _welcomeSpans) {
      if (remainingChars <= 0) break;

      int take = remainingChars > spanData.text.length
          ? spanData.text.length
          : remainingChars;
      String visibleText = spanData.text.substring(0, take);

      visibleSpans.add(
        TextSpan(
          text: visibleText,
          style: AppTypography.headlineSmall.copyWith(
            color: spanData.color,
            fontWeight: spanData.isBold ? FontWeight.bold : FontWeight.w500,
            shadows: spanData.isBold
                ? [
                    Shadow(
                      color: spanData.color.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      );

      remainingChars -= take;
    }
    return visibleSpans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (_isVideoInitialized && !_useVideoFallback)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceLowest, AppColors.surfaceLow],
                ),
              ),
            ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  AppColors.surfaceLowest.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),

          // Content
          FadeTransition(
            opacity: _opacityAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding
                  Text(
                    'GrowUp Ai',
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.kineticGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Typing Animation
                  SizedBox(
                    height: 120,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: _buildAnimatedSpans()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pulse Button
          if (_isTextComplete && _isVideoComplete)
            Positioned(
              bottom: 80,
              left: 32,
              right: 32,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: _navigateToNextPage,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.kineticGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'START JOURNEY',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TextSpanData {
  final String text;
  final Color color;
  final bool isBold;

  TextSpanData({required this.text, required this.color, this.isBold = false});
}
