import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> _onUserCreated(User user) async {
    // 1. Collect device fingerprint
    final deviceInfo = await _deviceService.collectDeviceInfo();

    // 2. Create Firestore user document with device info
    await FirestoreService().createUserIfNotExists(
      user,
      deviceId: deviceInfo.deviceId,
      deviceModel: deviceInfo.deviceModel,
      deviceOs: deviceInfo.deviceOs,
      deviceBrand: deviceInfo.brand,
    );

    // 3. Register device + check for suspicious activity (auto-blocks if needed)
    await _deviceService.registerAndCheckDevice(user.uid, deviceInfo);
  }

  /// Same logic for sign-in: update device info in case device changed.
  Future<void> _onUserSignedIn(User user) async {
    final deviceInfo = await _deviceService.collectDeviceInfo();
    await FirestoreService().createUserIfNotExists(
      user,
      deviceId: deviceInfo.deviceId,
      deviceModel: deviceInfo.deviceModel,
      deviceOs: deviceInfo.deviceOs,
      deviceBrand: deviceInfo.brand,
    );
  }

  // ── Sign in with Email and Password ─────────────────────────────────────────

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        await _onUserSignedIn(credential.user!);
      }
      return credential;
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
        await _onUserCreated(credential.user!);
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // ── Sign in with Google ──────────────────────────────────────────────────────

  Future<User?> signInWithGoogle() async {
    try {
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
        // For Google sign-in we don't know if it's new or returning, 
        // createUserIfNotExists handles both cases
        await _onUserCreated(userCredential.user!);
      }

      return userCredential.user;
    } catch (e) {
      rethrow;
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
