import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Provider to check if user is authenticated
final isUserAuthenticatedProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    // Check if user has completed onboarding and registration
    final String? userName = prefs.getString('userName');
    final String? userEmail = prefs.getString('userEmail');
    final bool isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
    
    // User is authenticated if they have a name, email, and completed onboarding
    return userName != null && userEmail != null && isOnboardingComplete;
  } catch (e) {
    return false;
  }
});

// Provider to get current user data
final currentUserProvider = FutureProvider<UserData?>((ref) async {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    final String? userName = prefs.getString('userName');
    final String? userEmail = prefs.getString('userEmail');
    
    if (userName != null && userEmail != null) {
      return UserData(
        name: userName,
        email: userEmail,
      );
    }
    return null;
  } catch (e) {
    return null;
  }
});

class UserData {
  final String name;
  final String email;

  UserData({
    required this.name,
    required this.email,
  });
}
