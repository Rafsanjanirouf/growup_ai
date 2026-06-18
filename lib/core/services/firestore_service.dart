import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Singleton-style Firestore service that writes to the default database.
/// All collections follow the flat root-collection schema in database_schema.md.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection refs ─────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _scanHistory => _db.collection('scan_history');
  CollectionReference get _habits => _db.collection('habits');
  CollectionReference get _dailyProg => _db.collection('daily_progress');
  CollectionReference get _coachUsage => _db.collection('coach_usage');
  CollectionReference get _outfitHistory => _db.collection('outfit_history');
  CollectionReference get _hairstyleHistory => _db.collection('hairstyle_history');
  CollectionReference get _generationUsage => _db.collection('generation_usage');

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
      await _users.doc(uid).update(data);
    } catch (e) {
      debugPrint('FirestoreService.updateUser error: $e');
      rethrow;
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

        'jawline_details': jawlineDetails,
        'cheekbone_details': cheekboneDetails,
        'eye_details': eyeDetails,
        'nose_details': noseDetails,
        'lip_details': lipDetails,
        'chin_details': chinDetails,
        'skin_details': skinDetails,

        'highlights': highlights,
        'suggestions': suggestions,
        // Only store image URL if backup is enabled
        'image_url': imageBackupEnabled ? (imageUrl ?? '') : '',
        'image_backup_enabled': imageBackupEnabled,
        'week_index': weekIndex,

        'created_at': FieldValue.serverTimestamp(),
      });

      // Also bump the user's aura_score + updated_at
      await _users.doc(userId).update({
        'aura_score': auraScore,
        'updated_at': FieldValue.serverTimestamp(),
      });
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

  // ══ AI COACH USAGE TRACKING ═════════════════════════════════════════════════

  /// Retrieves the number of tokens used by the user on a specific day.
  Future<int> getDailyTokenUsage({
    required String userId,
    required String dateKey,
  }) async {
    try {
      final docId = '${userId}_$dateKey';
      final doc = await _coachUsage.doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['tokens_used'] as num?)?.toInt() ?? 0;
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

  /// Increments the daily tokens and message count for a user in `/coach_usage/{userId_dateKey}`.
  /// Also aggregates global daily usage in `/daily_metrics/{dateKey}`.
  Future<void> trackChatUsage({
    required String userId,
    required String dateKey, // e.g., '2026-06-10'
    required int tokensUsed,
  }) async {
    try {
      // 1. Per-User Daily Tracking
      final docId = '${userId}_$dateKey';
      await _coachUsage.doc(docId).set({
        'id': docId,
        'user_id': userId,
        'date_key': dateKey,
        'tokens_used': FieldValue.increment(tokensUsed),
        'message_count': FieldValue.increment(1),
        'last_used_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Global Daily Aggregation
      await _db.collection('daily_metrics').doc(dateKey).set({
        'date_key': dateKey,
        'total_tokens': FieldValue.increment(tokensUsed),
        'total_inputs': FieldValue.increment(1),
        'active_users': FieldValue.arrayUnion([
          userId,
        ]), // Array of unique user IDs
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.trackChatUsage error: $e');
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

  Future<void> saveOutfitRecord({
    required String userId,
    required String id,
    required DateTime date,
    String? imageUrl,
    required Map<String, dynamic> fullData,
  }) async {
    try {
      await _outfitHistory.doc(id).set({
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

  // ══ HAIRSTYLE HISTORY ══════════════════════════════════════════════════════════

  Future<void> saveHairStyleRecord({
    required String userId,
    required String id,
    required DateTime date,
    String? imageUrl,
    required Map<String, dynamic> fullData,
    String? generatedImageUrl,
  }) async {
    try {
      await _hairstyleHistory.doc(id).set({
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
}
