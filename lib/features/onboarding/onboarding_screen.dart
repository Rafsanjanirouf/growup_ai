import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/voice_guide_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/bottom_action_button.dart';
import '../../shared/widgets/voice_guide_toggle.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerPageNarration(0);
    });
  }

  void _triggerPageNarration(int index) {
    String text = "";
    switch (index) {
      case 0:
        text = "Get a detailed AI rating and scientific analysis of your facial features with our professional scanner.";
        break;
      case 1:
        text = "Watch your real-time growth tree evolve as you complete your daily transformation tasks.";
        break;
      case 2:
        text = "Talk live with your dedicated AI Mentor for personalized grooming and mindset advice.";
        break;
      case 3:
        text = "Follow expert-designed journeys for skin and fitness that deliver lasting results.";
        break;
      case 4:
        text = "Access professional tools like the Outfit Stylist and Symmetry Analyzer to perfect your look.";
        break;
      case 5:
        text = "Join over fifty thousand users who trust GlowUp AI with their transformation journey.";
        break;
    }
    ref.read(voiceGuideProvider.notifier).speak(text);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Professional Face Scan',
      description: 'Get a detailed AI rating and analysis of your facial features with our scientific scanner.',
      icon: Icons.face_retouching_natural,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Real Growth Tree',
      description: 'Complete your daily tasks and watch your growth tree evolve in real-time as you improve.',
      icon: Icons.park,
      color: const Color(0xFF10B981), // Emerald Green
    ),
    OnboardingPage(
      title: 'Personal AI Assistant',
      description: 'Talk live with your dedicated AI Mentor for personalized grooming and mindset advice.',
      icon: Icons.chat_bubble,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Scientific Programs',
      description: 'Follow 14-30 day journeys designed by skin and fitness experts for lasting results.',
      icon: Icons.school,
      color: Colors.deepPurple,
    ),
    OnboardingPage(
      title: 'Pro AI Toolkits',
      description: 'Access the Outfit Stylist and Symmetry Analyzer to perfect your appearance and style.',
      icon: Icons.architecture,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Join 50k+ Glowers',
      description: 'Trusted globally for private, secure tracking. Your data is always safe with GlowUp AI.',
      icon: Icons.verified_user,
      color: AppColors.secondary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Optimized Parallax Background
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double scrollPosition = 0;
              try {
                if (_pageController.hasClients) {
                  scrollPosition = _pageController.page ?? 0;
                }
              } catch (_) {}
              
              return Positioned.fill(
                left: -(scrollPosition * 50), // Subtle parallax shift
                child: child!,
              );
            },
            child: Image.asset(
              'assets/image/avater_image.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
          
          // Blur Overlay (Matching Trust Reviews Page)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Content Page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
              _triggerPageNarration(page);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Navigation UI at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentPage == index ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Navigation Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            child: Text(
                              'Back',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        // Skip button
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/auth');
                          },
                          child: Text(
                            'Skip',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Main Action Button
                    BottomActionButton(
                      label: _currentPage == _pages.length - 1 ? 'Start Your Journey' : 'Next Step',
                      icon: _currentPage == _pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward_ios,
                      isPulsing: true, 
                      onTap: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.of(context).pushReplacementNamed('/trust-reviews');
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Global Voice Toggle (Draggable)
          const VoiceGuideToggle(),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Glassmorphic Icon Container
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      page.color.withValues(alpha: 0.3),
                      page.color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: page.color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  page.icon,
                  size: 70,
                  color: page.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
