import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/user_stats_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/onboarding/goal_selection_screen.dart';
import 'features/face_scan/face_scan_screen.dart';
import 'features/home/main_navigation_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/trust_reviews_screen.dart';
import 'features/monetization/coin_shop_screen.dart';
import 'features/onboarding/discovery_hub_screen.dart';
import 'features/face_scan/face_scan_intro_screen.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences (minimal blocking)
  final prefs = await SharedPreferences.getInstance();

  // Initialize cameras in background (don't block startup)
  _initializeCamerasInBackground();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GrowUpAIApp(),
    ),
  );
}

// Initialize cameras in background without blocking app startup
Future<void> _initializeCamerasInBackground() async {
  try {
    cameras = await availableCameras();
    debugPrint('Cameras initialized in background: ${cameras.length} available');
  } catch (e) {
    debugPrint('Error initializing cameras: $e');
  }
}

class GrowUpAIApp extends StatelessWidget {
  const GrowUpAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowUp AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.kineticNebulaTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/discovery': (context) => const DiscoveryHubScreen(),
        '/trust-reviews': (context) => const TrustReviewsScreen(),
        '/auth': (context) => const AuthScreen(),
        '/goals': (context) => const GoalSelectionScreen(),
        '/face-scan-intro': (context) => const FaceScanIntroScreen(),
        '/face-scan': (context) => const FaceScanScreen(),
        '/main-navigation': (context) => const MainNavigationScreen(),
        '/coin-shop': (context) => const CoinShopScreen(),
      },
    );
  }
}
