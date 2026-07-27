import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core Themes and Providers
import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'core/services/backup_preference_service.dart';
import 'core/services/notification_service.dart';

// Splash & Auth
import 'features/splash/splash_screen.dart';

// Onboarding Feature Screens
import 'features/onboarding/auth_screen.dart';
import 'features/onboarding/signup_screen.dart';
import 'features/onboarding/profile_setup_screen.dart';
import 'features/onboarding/goal_selection_screen.dart';
import 'features/onboarding/backup_consent_screen.dart';

// Scan Feature Screens
import 'features/scan/camera_scan_screen.dart';
import 'features/scan/scanning_process_screen.dart';
import 'features/scan/paywall_screen.dart';
import 'features/scan/locked_report_screen.dart';

// Dashboard, Analytics & Profile Screens
import 'features/dashboard/dashboard_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/backup_settings_screen.dart';


import 'features/ui_showcase/ui_showcase_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  final prefs = await SharedPreferences.getInstance();
  await BackupPreferenceService().init(prefs);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Failed to initialize Notification Service: $e');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const GrowUpAIApp(),
    ),
  );
}

class GrowUpAIApp extends StatelessWidget {
  const GrowUpAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowUp AI Lookmaxxing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Entry point: pure splash screen → AuthGate handles routing
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/goals': (context) => const GoalSelectionScreen(),
        '/backup-consent': (context) => const BackupConsentScreen(),
        '/camera-scan': (context) => const CameraScanScreen(),
        '/scanning-process': (context) => const ScanningProcessScreen(),
        '/paywall': (context) => const PaywallScreen(),
        '/locked-report': (context) => const LockedReportScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/backup-settings': (context) => const BackupSettingsScreen(),
        '/ui-showcase': (context) => const UiShowcaseScreen(),
      },
    );
  }
}
