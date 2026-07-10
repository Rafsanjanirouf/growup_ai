import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'device_service.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DeviceService _deviceService = DeviceService();

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Internal: validate limits and setup user ─────────────────────────────────

  Future<void> _validateAndSetupUser(User user, {String authProvider = 'auth-- email'}) async {
    final deviceInfo = await _deviceService.collectDeviceInfo();
    
    // 1. Check device and account limits. Throws DeviceLimitExceededException if violated.
    await _deviceService.registerAndCheckDevice(user.uid, deviceInfo);

    // 2. If limits pass, create or update Firestore user document
    await FirestoreService().createUserIfNotExists(
      user,
      deviceId: deviceInfo.deviceId,
      deviceModel: deviceInfo.deviceModel,
      deviceOs: deviceInfo.deviceOs,
      deviceBrand: deviceInfo.brand,
      authProvider: authProvider,
    );

    // 3. Get FCM Token and save it
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirestoreService().updateFcmToken(user.uid, token);
      }
    } catch (e) {
      debugPrint('FCM Token error: $e');
    }
  }

  // ── Sign in with Email and Password ─────────────────────────────────────────

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        await _validateAndSetupUser(credential.user!);
      }
      return credential;
    } on DeviceLimitExceededException catch (e) {
      await signOut(); // Prevent login
      throw Exception(e.message);
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    } catch (e) {
      rethrow;
    }
  }

  // ── Sign up with Email and Password ─────────────────────────────────────────

  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        await _validateAndSetupUser(credential.user!);
      }
      return credential;
    } on DeviceLimitExceededException catch (e) {
      await signOut(); // Prevent login
      throw Exception(e.message);
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    } catch (e) {
      rethrow;
    }
  }

  // ── Sign in with Google ──────────────────────────────────────────────────────

  Future<User?> signInWithGoogle() async {
    try {
      // Force account selector to show up
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _validateAndSetupUser(userCredential.user!, authProvider: 'auth-- google');
      }

      return userCredential.user;
    } on DeviceLimitExceededException catch (e) {
      await signOut(); // Prevent login
      throw Exception(e.message);
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    } catch (e) {
      rethrow;
    }
  }

  // ── Friendly error messages ───────────────────────────────────────────────────

  Exception _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Incorrect email or password.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password must be at least 6 characters.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Check your internet connection.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      default:
        return Exception(e.message ?? 'Authentication failed. Please try again.');
    }
  }

  // ── Forgot Password ──────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // ── Sign out ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // 1. Remove this device from user's active devices to free up a slot
    final user = _auth.currentUser;
    if (user != null) {
      await _deviceService.removeDevice(user.uid);
    }

    // 2. Perform standard sign out
    await _googleSignIn.signOut();
    await _auth.signOut();
    
    // 3. Clear RevenueCat cache to prevent Premium status from sharing across multiple accounts
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Purchases logOut error: $e');
    }
  }

  // ── Check if current user is blocked ────────────────────────────────────────

  Future<bool> isCurrentUserBlocked() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _deviceService.isUserBlocked(user.uid);
  }
}
