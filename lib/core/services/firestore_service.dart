import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

/// Singleton-style Firestore service that writes to the default database.
/// All collections follow the flat root-collection schema in database_schema.md.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'v2db');

  // ── Collection refs ─────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _scanHistory => _db.collection('scan_history');
  CollectionReference get _habits => _db.collection('habits');
  CollectionReference get _dailyProg => _db.collection('daily_progress');
  CollectionReference get _generationUsage => _db.collection('generation_usage');

  // ── User-scoped subcollection helpers ────────────────────────────────────────
  /// outfitHistory/{uid}/scans/{scanId}
  CollectionReference _outfitHistoryFor(String userId) =>
      _db.collection('outfitHistory').doc(userId).collection('scans');

  /// hairstyleHistory/{uid}/scans/{scanId}
  CollectionReference _hairstyleHistoryFor(String userId) =>
      _db.collection('hairstyleHistory').doc(userId).collection('scans');

  // ══ UTILS ═══════════════════════════════════════════════════════════════════

  Future<String?> uploadImage(
    String imagePath,
    String userId,
    String scanId, {
    String folder = 'scan_images',
  }) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('FirestoreService: Local image file does not exist at $imagePath');
        return null;
      }

      final tmpDir = await getTemporaryDirectory();
      final targetPath = '${tmpDir.path}/${scanId}_compressed.webp';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        format: CompressFormat.webp,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressed == null) {
        debugPrint('FirestoreService: image compression returned null');
        return null;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(folder)
          .child(userId)
          .child('$scanId.webp');

      final uploadTask = storageRef.putFile(
        File(compressed.path),
        SettableMetadata(contentType: 'image/webp'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('FirestoreService.uploadImage error: $e');
      return null;
    }
  }

  Future<String?> uploadBase64Image(String base64String, String userId, String scanId, String folder) async {
    try {
      final tmpDir = await getTemporaryDirectory();
      final targetPath = '${tmpDir.path}/${scanId}_$folder.webp';
      final file = File(targetPath);
      await file.writeAsBytes(base64Decode(base64String));

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(folder)
          .child(userId)
          .child('${scanId}_generated.webp');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/webp'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch(e) {
      debugPrint('FirestoreService.uploadBase64Image error: $e');
      return null;
    }
  }

  // ══ USERS ═══════════════════════════════════════════════════════════════════

  /// Creates a new user document in Firestore if one doesn't exist yet.
  /// Accepts optional device info fields collected at signup time.
  Future<void> createUserIfNotExists(
    User user, {
    String deviceId = '',
    String deviceModel = '',
    String deviceOs = '',
    String deviceBrand = '',
    String authProvider = 'auth-- email',
    String fcmToken = '',
  }) async {
    try {
      final doc = await _users.doc(user.uid).get();
      if (!doc.exists) {
        await _users.doc(user.uid).set({
          'id': user.uid,
          'email': user.email ?? '',
          'display_name': user.displayName ?? '',
          'photo_url': user.photoURL ?? '',
          'auth_provider': authProvider,
          'age': 18,
          'gender': '',
          'skin_type': '',
          'skinType': '',
          'budget': '',
          'goals': [],
          'problems': [],
          'current_streak': 0,
          'aura_score': 0.0,
          'is_pro': false,
          'onboarding_completed': false,
          'profileCompleted': false,
          'completedAt': null,
          'language': 'English',
          'languageLocale': 'en-US',
          // Device fingerprint fields
          'device_id': deviceId,
          'device_model': deviceModel,
          'device_os': deviceOs,
          'device_brand': deviceBrand,
          // Security / block fields
          'block': false,
          'block_date': null,
          'block_reason': '',
          'fcm_token': fcmToken,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // If user already exists, still update device info (e.g. login on new device)
        final updateData = <String, dynamic>{
          'updated_at': FieldValue.serverTimestamp(),
          'auth_provider': authProvider,
        };
        if (deviceId.isNotEmpty) {
          updateData['device_id'] = deviceId;
          updateData['device_model'] = deviceModel;
          updateData['device_os'] = deviceOs;
          updateData['device_brand'] = deviceBrand;
        }
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          updateData['display_name'] = user.displayName;
        }
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          updateData['photo_url'] = user.photoURL;
        }
        if (user.email != null && user.email!.isNotEmpty) {
          updateData['email'] = user.email;
        }
        await _users.doc(user.uid).update(updateData);
      }
    } catch (e) {
      debugPrint('FirestoreService.createUserIfNotExists error: $e');
      rethrow;
    }
  }

  /// Updates any subset of user profile fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = FieldValue.serverTimestamp();
      await _users.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.updateUser error: $e');
      rethrow;
    }
  }

  /// Updates FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _users.doc(uid).update({'fcm_token': token});
    } catch (e) {
      debugPrint('FirestoreService.updateFcmToken error: $e');
    }
  }

  /// Fetches user document data from Firestore.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>?;
      return null;
    } catch (e) {
      debugPrint('FirestoreService.getUserData error: $e');
      return null;
    }
  }

  /// Stores backup preference config on the user document for server analytics.
  /// Fields written: backup_enabled, backup_consent_shown, backup_consent_at,
  /// backup_updated_at. Uses set(merge:true) so it works even before full
  /// profile creation.
  Future<void> updateUserBackupConfig(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _users.doc(uid).set({
        ...fields,
        'backup_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.updateUserBackupConfig error: $e');
      rethrow;
    }
  }

  /// Saves a minimal scan summary when full Gemini data is not available.
  /// Used by SyncService as a fallback when `full_data` is missing.
  Future<void> saveScanSummary({
    required String userId,
    required String scanId,
    required DateTime scanDate,
    required double auraScore,
    required double jawlineScore,
    required double skinScore,
    required double eyeScore,
    required double postureScore,
    required String rating,
    required List<String> highlights,
    String? imageUrl,
    int weekIndex = 0,
    bool imageBackupEnabled = true,
  }) async {
    try {
      await _scanHistory.doc(scanId).set({
        'id': scanId,
        'user_id': userId,
        'scan_date': Timestamp.fromDate(scanDate),
        'aura_score': auraScore / 10, // store as 1–10
        'overall_score': auraScore,
        'symmetry_score': jawlineScore,
        'posture_score': postureScore,
        'rating': rating,
        'highlights': highlights,
        // Only store image URL if backup is enabled
        'image_url': imageBackupEnabled ? (imageUrl ?? '') : '',
        'image_backup_enabled': imageBackupEnabled,
        'week_index': weekIndex,
        'created_at': FieldValue.serverTimestamp(),
        // Minimal empty detail maps
        'skin_details': {'texture': skinScore},
        'eye_details': {'alertness': eyeScore},
        'jawline_details': {},
        'cheekbone_details': {},
        'nose_details': {},
        'lip_details': {},
        'chin_details': {},
        'suggestions': [],
        'golden_ratio_score': 65.0,
        'cuteness_score': 65.0,
        'hotness_score': 65.0,
        'domination_score': 65.0,
      }, SetOptions(merge: true));

      await _users.doc(userId).update({
        'aura_score': auraScore,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService.saveScanSummary error: $e');
      rethrow;
    }
  }

  // ══ SCAN HISTORY ════════════════════════════════════════════════════════════

  /// Saves a full scan record to `/scan_history/{scanId}`.
  /// All fields match the `scan_history` table in database_schema.md.
  Future<void> saveScanRecord({
    required String userId,
    required String scanId,
    required DateTime scanDate,

    // Top-level scores
    required double overallScore,
    required double auraScore,
    required double symmetryScore,
    required double goldenRatioScore,
    required double cutenessScore,
    required double hotnessScore,
    required double dominationScore,
    required double postureScore,
    required String rating,

    // New comprehensive metrics
    required String faceShape,
    required double faceSymmetry,
    required double skinHealthScore,
    required String acneDetection,
    required int faceAgeEstimation,
    required String darkCircles,
    required double hairDensity,
    required double overallAiFaceScore,

    // Detail JSON blocks
    required Map<String, dynamic> jawlineDetails,
    required Map<String, dynamic> cheekboneDetails,
    required Map<String, dynamic> eyeDetails,
    required Map<String, dynamic> noseDetails,
    required Map<String, dynamic> lipDetails,
    required Map<String, dynamic> chinDetails,
    required Map<String, dynamic> skinDetails,

    // Lists
    required List<String> highlights,
    required List<String> suggestions,

    // Optional
    String? imageUrl,
    int weekIndex = 0,
    bool imageBackupEnabled = true,
  }) async {
    try {
      await _scanHistory.doc(scanId).set({
        'id': scanId,
        'user_id': userId,
        'scan_date': Timestamp.fromDate(scanDate),

        'overall_score': overallScore,
        'aura_score': auraScore,
        'symmetry_score': symmetryScore,
        'golden_ratio_score': goldenRatioScore,
        'cuteness_score': cutenessScore,
        'hotness_score': hotnessScore,
        'domination_score': dominationScore,
        'posture_score': postureScore,
        'rating': rating,

        // Comprehensive metrics
        'face_shape': faceShape,
        'face_symmetry': faceSymmetry,
        'skin_health_score': skinHealthScore,
        'acne_detection': acneDetection,
        'face_age_estimation': faceAgeEstimation,
        'dark_circles': darkCircles,
        'hair_density': hairDensity,
        'overall_ai_face_score': overallAiFaceScore,

        'jawline_details': jawlineDetails,
        'cheekbone_details': cheekboneDetails,
        'eye_details': eyeDetails,
        'nose_details': noseDetails,
        'lip_details': lipDetails,
        'chin_details': chinDetails,
        'skin_details': skinDetails,

        'highlights': highlights,
        'suggestions': suggestions,
        'image_url': imageUrl ?? '',
        'image_backup_enabled': imageBackupEnabled,
        'week_index': weekIndex,

        'created_at': FieldValue.serverTimestamp(),
      });

      // Also bump the user's aura_score + updated_at
      await _users.doc(userId).set({
        'aura_score': auraScore,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveScanRecord error: $e');
      rethrow;
    }
  }

  /// Fetches all scans for a specific user (newest first).
  Future<List<Map<String, dynamic>>> getUserScans(String userId) async {
    try {
      final snapshot = await _scanHistory
          .where('user_id', isEqualTo: userId)
          .get();
      final docs = snapshot.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();
      docs.sort((a, b) {
        final aTime =
            (a['scan_date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime =
            (b['scan_date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return docs;
    } catch (e) {
      debugPrint('FirestoreService.getUserScans error: $e');
      return [];
    }
  }

  // ══ HABITS ══════════════════════════════════════════════════════════════════

  /// Upserts a habit document to `/habits/{habitId}`.
  Future<void> saveHabit({
    required String habitId,
    required String title,
    required String description,
    required String timeOfDay,
    required String icon,
  }) async {
    try {
      await _habits.doc(habitId).set({
        'id': habitId,
        'title': title,
        'description': description,
        'time_of_day': timeOfDay,
        'icon': icon,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveHabit error: $e');
    }
  }

  // ══ DAILY PROGRESS ══════════════════════════════════════════════════════════

  /// Records a user's daily progress for the given date key (e.g. '2026-06-02').
  Future<void> saveDailyProgress({
    required String userId,
    required String dateKey,
    required int completedCount,
    required int totalCount,
  }) async {
    try {
      final docId = '${userId}_$dateKey';
      await _dailyProg.doc(docId).set({
        'id': docId,
        'user_id': userId,
        'date_key': dateKey,
        'timestamp': FieldValue.serverTimestamp(),
        'completed_count': completedCount,
        'total_count': totalCount,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveDailyProgress error: $e');
    }
  }

  /// Retrieves a user's daily progress history
  Future<List<Map<String, dynamic>>> getUserDailyProgress(String userId) async {
    try {
      final snap = await _dailyProg
          .where('user_id', isEqualTo: userId)
          .orderBy('date_key', descending: true)
          .get();
      return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('FirestoreService.getUserDailyProgress error: $e');
      return [];
    }
  }

  // ══ AI COACH USAGE TRACKING ═════════════════════════════════════════════════

  /// Retrieves the token usage for a specific day.
  /// If [category] is provided, returns only that category's token count
  /// (e.g. 'coach' for chat only). Otherwise returns the grand total.
  Future<int> getDailyTokenUsage({
    required String userId,
    required String dateKey,
    String? category,
  }) async {
    try {
      final docId = '${userId}_$dateKey';
      final doc = await _db.collection('ai_usage_tracking').doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (category != null) {
          // Return only the specified category's token count
          final categories = data['categories'] as Map<String, dynamic>?;
          return (categories?[category] as num?)?.toInt() ?? 0;
        }
        return (data['total_tokens_used'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('FirestoreService.getDailyTokenUsage error: $e');
      return 0;
    }
  }

  /// Retrieves the global daily token limit from app settings.
  Future<int> getDailyTokenLimit() async {
    try {
      final doc = await _db.collection('app_settings').doc('limits').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Default to 50000 if not set in the document
        return (data['daily_chat_tokens'] as num?)?.toInt() ?? 50000;
      }
      return 50000;
    } catch (e) {
      debugPrint('FirestoreService.getDailyTokenLimit error: $e');
      return 50000;
    }
  }



  // ══ AI USAGE TRACKING (ALL IN ONE) ═════════════════════════════════════════════════

  /// Comprehensive AI token tracking using Batch Writes for instant Analytics.
  Future<void> trackAiUsage({
    required String userId,
    required String dateKey,
    required String category,
    required int tokensUsed,
  }) async {
    try {
      final batch = _db.batch();

      // 1. User's Daily Usage (How much a user spent today and where)
      final dailyUserRef = _db.collection('ai_usage_tracking').doc('${userId}_$dateKey');
      batch.set(dailyUserRef, {
        'id': '${userId}_$dateKey',
        'user_id': userId,
        'date_key': dateKey,
        'total_tokens_used': FieldValue.increment(tokensUsed),
        'categories': {
          category: FieldValue.increment(tokensUsed)
        },
        'last_used_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. User's Lifetime Usage (Who is spending the most & where)
      final userRef = _db.collection('users').doc(userId);
      batch.set(userRef, {
        'lifetime_tokens_used': FieldValue.increment(tokensUsed),
        'ai_categories_usage': {
          category: FieldValue.increment(tokensUsed)
        }
      }, SetOptions(merge: true));

      // 3. Global Daily Usage (Which day costs the most & in which category)
      final dailyGlobalRef = _db.collection('global_stats').doc('daily_$dateKey');
      batch.set(dailyGlobalRef, {
        'date_key': dateKey,
        'total_tokens': FieldValue.increment(tokensUsed),
        'categories': {
          category: FieldValue.increment(tokensUsed)
        }
      }, SetOptions(merge: true));

      // 4. Global Lifetime Usage (Overall app token consumption)
      final globalRef = _db.collection('global_stats').doc('lifetime_ai_usage');
      batch.set(globalRef, {
        'total_tokens': FieldValue.increment(tokensUsed),
        'categories': {
          category: FieldValue.increment(tokensUsed)
        }
      }, SetOptions(merge: true));

      // Execute all 4 updates atomically
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService.trackAiUsage error: $e');
    }
  }

  // ══ AI GENERATION USAGE TRACKING ═════════════════════════════════════════════════

  /// Retrieves the daily limit for Image-to-Text generation.
  Future<int> getDailyImageToTextLimit() async {
    try {
      final doc = await _db.collection('app_settings').doc('limits').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['daily_image_to_text_limit'] as num?)?.toInt() ?? 50;
      }
      return 50;
    } catch (e) {
      debugPrint('FirestoreService.getDailyImageToTextLimit error: $e');
      return 50;
    }
  }

  /// Retrieves the monthly limit for premium Image Generation.
  Future<int> getMonthlyImageGenerationLimit() async {
    try {
      final doc = await _db.collection('app_settings').doc('limits').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['monthly_image_generation_limit'] as num?)?.toInt() ?? 5;
      }
      return 5;
    } catch (e) {
      debugPrint('FirestoreService.getMonthlyImageGenerationLimit error: $e');
      return 5;
    }
  }

  /// Gets how many image-to-text calls the user has made today.
  Future<int> getDailyImageToTextUsage({
    required String userId,
    required String dateKey,
  }) async {
    try {
      final docId = '${userId}_$dateKey';
      final doc = await _generationUsage.doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['image_to_text_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('FirestoreService.getDailyImageToTextUsage error: $e');
      return 0;
    }
  }

  /// Increments the daily image-to-text usage.
  Future<void> trackImageToTextUsage({
    required String userId,
    required String dateKey,
  }) async {
    try {
      final docId = '${userId}_$dateKey';
      await _generationUsage.doc(docId).set({
        'id': docId,
        'user_id': userId,
        'date_key': dateKey,
        'image_to_text_count': FieldValue.increment(1),
        'last_used_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.trackImageToTextUsage error: $e');
    }
  }

  /// Gets how many image generation calls the user has made this month.
  Future<int> getMonthlyImageGenerationUsage({
    required String userId,
    required String monthKey,
  }) async {
    try {
      final docId = '${userId}_$monthKey';
      final doc = await _generationUsage.doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['image_generation_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('FirestoreService.getMonthlyImageGenerationUsage error: $e');
      return 0;
    }
  }

  /// Increments the monthly image generation usage.
  Future<void> trackImageGenerationUsage({
    required String userId,
    required String monthKey,
  }) async {
    try {
      final docId = '${userId}_$monthKey';
      await _generationUsage.doc(docId).set({
        'id': docId,
        'user_id': userId,
        'month_key': monthKey,
        'image_generation_count': FieldValue.increment(1),
        'last_used_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.trackImageGenerationUsage error: $e');
    }
  }

  // ══ DATA DELETION (Backup OFF / GDPR) ════════════════════════════════════════

  /// Deletes all scan_history and habits documents belonging to [userId].
  /// The `users` document is kept (account identity + billing).
  /// Called when user disables backup and chooses to erase cloud data.
  Future<void> deleteUserScanData(String userId) async {
    try {
      // Delete scan_history docs
      final scans = await _scanHistory
          .where('user_id', isEqualTo: userId)
          .get();
      final batch1 = _db.batch();
      for (final doc in scans.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();

      // Delete habits docs
      final habits = await _habits.where('user_id', isEqualTo: userId).get();
      final batch2 = _db.batch();
      for (final doc in habits.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();

      // Delete daily_progress docs
      final progress = await _dailyProg
          .where('user_id', isEqualTo: userId)
          .get();
      final batch3 = _db.batch();
      for (final doc in progress.docs) {
        batch3.delete(doc.reference);
      }
      await batch3.commit();

      debugPrint(
        'FirestoreService.deleteUserScanData: deleted all cloud data for $userId',
      );
    } catch (e) {
      debugPrint('FirestoreService.deleteUserScanData error: $e');
      rethrow;
    }
  }

  // ══ OUTFIT HISTORY ══════════════════════════════════════════════════════════
  // Path: outfitHistory/{userId}/scans/{scanId}

  Future<void> saveOutfitRecord({
    required String userId,
    required String id,
    required DateTime date,
    String? imageUrl,
    required Map<String, dynamic> fullData,
  }) async {
    try {
      await _outfitHistoryFor(userId).doc(id).set({
        'id': id,
        'user_id': userId,
        'date': Timestamp.fromDate(date),
        'image_url': imageUrl ?? '',
        'full_data': fullData,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService.saveOutfitRecord error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOutfitScans(String userId) async {
    try {
      final snapshot = await _outfitHistoryFor(userId).get();
      final docs = snapshot.docs.map((e) => e.data() as Map<String, dynamic>).toList();
      docs.sort((a, b) {
        final aTime = (a['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime = (b['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return docs;
    } catch (e) {
      debugPrint('FirestoreService.getOutfitScans error: $e');
      return [];
    }
  }

  Future<void> deleteOutfitRecord(String userId, String id) async {
    try {
      await _outfitHistoryFor(userId).doc(id).delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteOutfitRecord error: $e');
    }
  }

  // ══ HAIRSTYLE HISTORY ══════════════════════════════════════════════════════════
  // Path: hairstyleHistory/{userId}/scans/{scanId}

  Future<void> saveHairStyleRecord({
    required String userId,
    required String id,
    required DateTime date,
    String? imageUrl,
    required Map<String, dynamic> fullData,
    String? generatedImageUrl,
  }) async {
    try {
      await _hairstyleHistoryFor(userId).doc(id).set({
        'id': id,
        'user_id': userId,
        'date': Timestamp.fromDate(date),
        'image_url': imageUrl ?? '',
        'full_data': fullData,
        'generated_image_url': generatedImageUrl ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService.saveHairStyleRecord error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHairStyleScans(String userId) async {
    try {
      final snapshot = await _hairstyleHistoryFor(userId).get();
      final docs = snapshot.docs.map((e) => e.data() as Map<String, dynamic>).toList();
      docs.sort((a, b) {
        final aTime = (a['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime = (b['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return docs;
    } catch (e) {
      debugPrint('FirestoreService.getHairStyleScans error: $e');
      return [];
    }
  }

  Future<void> deleteHairStyleRecord(String userId, String id) async {
    try {
      await _hairstyleHistoryFor(userId).doc(id).delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteHairStyleRecord error: $e');
    }
  }

  // ── TASKS SYNC ───────────────────────────────────────────────────────────────

  /// Saves daily tasks array to Firestore under users/{uid}/tasks/{date}
  Future<void> saveDailyTasks({
    required String userId,
    required DateTime date,
    required List<Map<String, dynamic>> tasksList,
  }) async {
    try {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final ref = _db
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(dateStr);

      await ref.set({
        'date': dateStr,
        'items': tasksList,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveDailyTasks error: $e');
      rethrow;
    }
  }

  // ══ CHAT SESSIONS & MESSAGES ═══════════════════════════════════════════════

  Future<void> createChatSession({
    required String userId,
    required String sessionId,
    required String title,
    required DateTime updatedAt,
  }) async {
    try {
      await _users.doc(userId).collection('chat_sessions').doc(sessionId).set({
        'id': sessionId,
        'title': title,
        'updated_at': Timestamp.fromDate(updatedAt),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.createChatSession error: $e');
    }
  }

  Future<void> updateChatSessionDate(String userId, String sessionId, DateTime updatedAt) async {
    try {
      await _users.doc(userId).collection('chat_sessions').doc(sessionId).update({
        'updated_at': Timestamp.fromDate(updatedAt),
      });
    } catch (e) {
      debugPrint('FirestoreService.updateChatSessionDate error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChatSessions(String userId) async {
    try {
      final snapshot = await _users
          .doc(userId)
          .collection('chat_sessions')
          .orderBy('updated_at', descending: true)
          .get();
      return snapshot.docs.map((e) => e.data()).toList();
    } catch (e) {
      debugPrint('FirestoreService.getChatSessions error: $e');
      return [];
    }
  }

  Future<void> deleteChatSession(String userId, String sessionId) async {
    try {
      final messages = await _users
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .get();
      final batch = _db.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_users.doc(userId).collection('chat_sessions').doc(sessionId));
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService.deleteChatSession error: $e');
    }
  }

  Future<void> saveChatMessage({
    required String userId,
    required String sessionId,
    required String messageId,
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) async {
    try {
      await _users
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'text': text,
        'is_user': isUser,
        'timestamp': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      debugPrint('FirestoreService.saveChatMessage error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId, String sessionId) async {
    try {
      final snapshot = await _users
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      return snapshot.docs.map((e) => e.data()).toList();
    } catch (e) {
      debugPrint('FirestoreService.getChatMessages error: $e');
      return [];
    }
  }

  // ══ EXIT SURVEYS ═══════════════════════════════════════════════════════════

  /// Saves an exit survey to a specific collection (e.g. 'prememership complain' or 'pree scan')
  Future<void> saveExitSurvey({
    required String userId,
    required String collectionName,
    required List<String> reasons,
    required String customText,
  }) async {
    try {
      await _db.collection(collectionName).doc(userId).set({
        'user_id': userId,
        'reasons': reasons,
        'custom_text': customText,
        'timestamp': FieldValue.serverTimestamp(),
        'complaint_count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveExitSurvey error: $e');
      rethrow;
    }
  }
}
