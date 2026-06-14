import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'device_service.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DeviceService _deviceService = DeviceService();

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Internal: collect device info, save user, register device ──────────────

  Future<void> _onUserCreated(User user, {String authProvider = 'auth-- email'}) async {
    // Fire-and-forget: device/Firestore errors must never block auth
    try {
      final deviceInfo = await _deviceService.collectDeviceInfo();
      await FirestoreService().createUserIfNotExists(
        user,
        deviceId: deviceInfo.deviceId,
        deviceModel: deviceInfo.deviceModel,
        deviceOs: deviceInfo.deviceOs,
        deviceBrand: deviceInfo.brand,
        authProvider: authProvider,
      );
      await _deviceService.registerAndCheckDevice(user.uid, deviceInfo);
    } catch (e) {
      debugPrint('AuthService._onUserCreated (non-fatal): $e');
    }
  }

  /// Same logic for sign-in: update device info in case device changed.
  Future<void> _onUserSignedIn(User user, {String authProvider = 'auth-- email'}) async {
    // Fire-and-forget: device/Firestore errors must never block auth
    try {
      final deviceInfo = await _deviceService.collectDeviceInfo();
      await FirestoreService().createUserIfNotExists(
        user,
        deviceId: deviceInfo.deviceId,
        deviceModel: deviceInfo.deviceModel,
        deviceOs: deviceInfo.deviceOs,
        deviceBrand: deviceInfo.brand,
        authProvider: authProvider,
      );
    } catch (e) {
      debugPrint('AuthService._onUserSignedIn (non-fatal): $e');
    }
  }

  // ── Sign in with Email and Password ─────────────────────────────────────────

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        _onUserSignedIn(credential.user!); // non-blocking
      }
      return credential;
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
        _onUserCreated(credential.user!); // non-blocking
      }
      return credential;
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
        _onUserCreated(userCredential.user!, authProvider: 'auth-- google'); // non-blocking
      }

      return userCredential.user;
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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Check if current user is blocked ────────────────────────────────────────

  Future<bool> isCurrentUserBlocked() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _deviceService.isUserBlocked(user.uid);
  }
}
