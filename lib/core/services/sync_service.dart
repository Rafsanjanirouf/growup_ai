import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/local_db_service.dart';
import '../services/gemini_service.dart';
import '../services/backup_preference_service.dart';
import '../providers/scan_history_provider.dart';
import 'package:firebase_core/firebase_core.dart';

/// Background sync service.
/// - Text/score data is ALWAYS pushed to Firestore (survives app data clear).
/// - Image URL is only included when backup preference is ON.
/// - Pulls remote scan records not present locally (new device recovery).
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalDbService _local = LocalDbService();
  final FirestoreService _remote = FirestoreService();

  // ── TASKS SYNC ───────────────────────────────────────────────────────────────

  /// Pushes the daily task JSON array to Firestore
  Future<void> syncDailyTasks(DateTime date, List<dynamic> tasks) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tasksList = tasks.map((t) {
        // Assume t is Habit object, we convert to map manually
        return {
          'id': t.id,
          'title': t.title,
          'timeOfDay': t.timeOfDay,
          'isCompleted': t.isCompleted,
          'targetCount': t.targetCount,
          'currentCount': t.currentCount,
          'icon': t.icon,
        };
      }).toList();

      await _remote.saveDailyTasks(
        userId: user.uid,
        date: date,
        tasksList: tasksList,
      );
    } catch (e) {
      debugPrint('SyncService.syncDailyTasks error: $e');
    }
  }

  // ── PUSH: local → Firestore ──────────────────────────────────────────────────

  /// Finds all local scans with `isSynced = false` and pushes them to Firestore.
  /// Text/score data always syncs. Image URL only included if backup is enabled.
  Future<void> syncPendingScans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final imageBackupEnabled = BackupPreferenceService().isBackupEnabled;

    try {
      final pending = await _local.getUnsyncedScans(user.uid);
      if (pending.isEmpty) return;

      debugPrint('SyncService: ${pending.length} unsynced scan(s) to push');

      // All scans for week_index computation
      final allScans = await _local.getAllScans(user.uid);

      for (final row in pending) {
        final scanId = row['id'] as String;
        final fullData = LocalDbService.parseFullData(row['full_data']);
        final rawWeekIndex = (row['week_index'] as int?) ?? 0;
        final weekIndex = rawWeekIndex > 0
            ? rawWeekIndex
            : _computeWeekIndex(row['date'] as String, allScans);

        // Upload local image if backup is enabled and URL is a local path
        String? finalImageUrl = row['image_url'] as String?;
        if (imageBackupEnabled && finalImageUrl != null && finalImageUrl.isNotEmpty) {
          final isNetwork = finalImageUrl.startsWith('http://') || finalImageUrl.startsWith('https://');
          if (!isNetwork) {
            debugPrint('SyncService: uploading local image path $finalImageUrl for scan $scanId...');
            final cloudUrl = await uploadImage(finalImageUrl, user.uid, scanId);
            if (cloudUrl != null) {
              finalImageUrl = cloudUrl;
              await _local.updateImageUrl(scanId, cloudUrl);
            }
          }
        }

        try {
          if (fullData != null) {
            final now   = DateTime.parse(row['date'] as String);
            final score = (row['aura_score'] as num).toDouble();

            await _remote.saveScanRecord(
              userId:             user.uid,
              scanId:             scanId,
              scanDate:           now,
              overallScore:       GeminiService.safeDouble(fullData['overall_score'], score),
              auraScore:          GeminiService.safeDouble(fullData['aura_score'], score / 10),
              symmetryScore:      GeminiService.safeDouble(fullData['symmetry_score'], (row['jawline_score'] as num).toDouble()),
              goldenRatioScore:   GeminiService.safeDouble(fullData['golden_ratio_score'], 65.0),
              cutenessScore:      GeminiService.safeDouble(fullData['cuteness_score'], 65.0),
              hotnessScore:       GeminiService.safeDouble(fullData['hotness_score'], 65.0),
              dominationScore:    GeminiService.safeDouble(fullData['domination_score'], 65.0),
              postureScore:       (row['posture_score'] as num).toDouble(),
              rating:             row['rating'] as String,
              jawlineDetails:     GeminiService.safeMap(fullData['jawline_details']),
              cheekboneDetails:   GeminiService.safeMap(fullData['cheekbone_details']),
              eyeDetails:         GeminiService.safeMap(fullData['eye_details']),
              noseDetails:        GeminiService.safeMap(fullData['nose_details']),
              lipDetails:         GeminiService.safeMap(fullData['lip_details']),
              chinDetails:        GeminiService.safeMap(fullData['chin_details']),
              skinDetails:        GeminiService.safeMap(fullData['skin_details']),
              highlights:         GeminiService.safeStringList(fullData['highlights']),
              suggestions:        GeminiService.safeStringList(fullData['suggestions']),
              imageUrl:           imageBackupEnabled ? finalImageUrl : null,
              weekIndex:          weekIndex,
              imageBackupEnabled: imageBackupEnabled,
            );
          } else {
            await _remote.saveScanSummary(
              userId:             user.uid,
              scanId:             scanId,
              scanDate:           DateTime.parse(row['date'] as String),
              auraScore:          (row['aura_score'] as num).toDouble(),
              jawlineScore:       (row['jawline_score'] as num).toDouble(),
              skinScore:          (row['skin_score'] as num).toDouble(),
              eyeScore:           (row['eye_score'] as num).toDouble(),
              postureScore:       (row['posture_score'] as num).toDouble(),
              rating:             row['rating'] as String,
              highlights:         LocalDbService.parseHighlights(row['highlights']),
              imageUrl:           imageBackupEnabled ? finalImageUrl : null,
              weekIndex:          weekIndex,
              imageBackupEnabled: imageBackupEnabled,
            );
          }

          await _local.markSynced(scanId);
          debugPrint('SyncService: synced scan $scanId (week=$weekIndex) ✓');
        } catch (e) {
          debugPrint('SyncService: failed to sync $scanId (will retry): $e');
        }
      }
    } catch (e) {
      debugPrint('SyncService.syncPendingScans error: $e');
    }
  }

  // ── PULL: Firestore → local ──────────────────────────────────────────────────

  /// Fetches remote scans and imports any that are missing locally.
  /// Always runs regardless of backup preference so users can recover data.
  Future<List<ScanRecord>> fetchRemoteScans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final imported = <ScanRecord>[];

    try {
      final remoteDocs = await _remote.getUserScans(user.uid);
      debugPrint('SyncService: ${remoteDocs.length} remote scan(s) found');

      for (final doc in remoteDocs) {
        final scanId = doc['id'] as String? ?? '';
        if (scanId.isEmpty) continue;

        final alreadyExists = await _local.exists(scanId);
        if (alreadyExists) continue;

        try {
          final date        = _parseDate(doc['scan_date']);
          final auraScore   = GeminiService.safeDouble(doc['aura_score'], 6.5) * 10;
          final jawline     = GeminiService.safeDouble(doc['symmetry_score'], 65.0);
          final skinDetails = GeminiService.safeMap(doc['skin_details']);
          final eyeDetails  = GeminiService.safeMap(doc['eye_details']);
          final skin        = GeminiService.safeDouble(skinDetails['texture'], 65.0);
          final eye         = GeminiService.safeDouble(eyeDetails['alertness'], 65.0);
          final posture     = GeminiService.safeDouble(doc['posture_score'], 65.0);
          final rating      = GeminiService.safeString(doc['rating'], ScanRecord.computeRating(auraScore));
          final highlights  = GeminiService.safeStringList(doc['highlights']);
          final weekIndex   = (doc['week_index'] as int?) ?? 0;
          // Only restore image URL if it was backed up
          final imageBackedUp = doc['image_backup_enabled'] as bool? ?? true;
          final rawImageUrl   = doc['image_url'] as String?;
          final imageUrl      = imageBackedUp && rawImageUrl != null && rawImageUrl.isNotEmpty
              ? rawImageUrl
              : null;

          await _local.insertScan(
            id:           scanId,
            userId:       user.uid,
            date:         date,
            auraScore:    auraScore,
            jawlineScore: jawline,
            skinScore:    skin,
            eyeScore:     eye,
            postureScore: posture,
            rating:       rating,
            highlights:   highlights,
            imageUrl:     imageUrl,
            weekIndex:    weekIndex,
            isSynced:     true,
          );

          imported.add(ScanRecord(
            id:           scanId,
            date:         date,
            auraScore:    auraScore,
            jawlineScore: jawline,
            skinScore:    skin,
            eyeScore:     eye,
            postureScore: posture,
            rating:       rating,
            highlights:   highlights,
            imageUrl:     imageUrl,
            weekIndex:    weekIndex,
            isSynced:     true,
          ));

          debugPrint('SyncService: imported scan $scanId (week=$weekIndex) ✓');
        } catch (e) {
          debugPrint('SyncService: failed to import scan $scanId: $e');
        }
      }
    } catch (e) {
      debugPrint('SyncService.fetchRemoteScans error: $e');
    }

    return imported;
  }

  /// Fetches the last 7 days of daily progress from Firestore
  Future<List<Map<String, dynamic>>> fetchRemoteDailyProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'growupai',
      );
      final snapshot = await db.collection('daily_progress')
          .where('user_id', isEqualTo: user.uid)
          .get();
      
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('SyncService.fetchRemoteDailyProgress error: $e');
      return [];
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Sequential week index: position of this scan among all scans (oldest = 1).
  /// Helper to upload a local image to Firebase Storage (compressed format).
  Future<String?> uploadImage(String imagePath, String userId, String scanId) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('SyncService: Local image file does not exist at $imagePath');
        return null;
      }

      final tmpDir = await getTemporaryDirectory();
      final targetPath = '${tmpDir.path}/${scanId}_compressed.webp';

      // Compress to WebP at 80% quality (significantly smaller than JPEG)
      final compressed = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        format: CompressFormat.webp,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressed == null) {
        debugPrint('SyncService: image compression returned null, using original');
        return null;
      }

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('scan_images')
          .child(userId)
          .child('$scanId.webp');

      final uploadTask = storageRef.putFile(
        File(compressed.path),
        SettableMetadata(contentType: 'image/webp'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('SyncService: image uploaded → $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('SyncService.uploadImage error (non-fatal): $e');
      return null;
    }
  }

  int _computeWeekIndex(String dateStr, List<Map<String, dynamic>> allScans) {
    final sorted = List<Map<String, dynamic>>.from(allScans)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    int idx = 1;
    for (final row in sorted) {
      if ((row['date'] as String) == dateStr) return idx;
      idx++;
    }
    return idx;
  }

  DateTime _parseDate(dynamic raw) {
    try {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.parse(raw);
      if (raw is Map) {
        final secs = raw['_seconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
      }
    } catch (_) {}
    return DateTime.now();
  }
}