import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'user_provider.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class ScanRecord {
  final String id;
  final DateTime date;
  final double auraScore;
  final double jawlineScore;
  final double skinScore;
  final double eyeScore;
  final double postureScore;
  
  // New comprehensive metrics
  final String faceShape;
  final double faceSymmetry;
  final double skinHealthScore;
  final String acneDetection;
  final int faceAgeEstimation;
  final String darkCircles;
  final double hairDensity;
  final double overallAiFaceScore;

  final String rating; // 'Legendary' | 'Elite' | 'Rising' | 'Developing'
  final List<String> highlights; // top AI insights
  final String? imageUrl; // Firebase Storage URL (nullable — may not exist)
  /// Sequential week number from user's first scan (1-based).
  /// If 0 it means it was a pre-migration record.
  final int weekIndex;
  final Map<String, dynamic>? fullData;

  /// true = already pushed to Firestore; false = pending sync
  final bool isSynced;

  ScanRecord({
    required this.id,
    required this.date,
    required this.auraScore,
    required this.jawlineScore,
    required this.skinScore,
    required this.eyeScore,
    required this.postureScore,

    // Comprehensive metrics
    this.faceShape = 'Oval',
    this.faceSymmetry = 0.0,
    this.skinHealthScore = 0.0,
    this.acneDetection = 'Clear',
    this.faceAgeEstimation = 20,
    this.darkCircles = 'None',
    this.hairDensity = 0.0,
    this.overallAiFaceScore = 0.0,

    required this.rating,
    required this.highlights,
    this.imageUrl,
    this.weekIndex = 0,
    this.fullData,
    this.isSynced = false,
  });

  /// Calculate the ISO-style week number within the year (used as fallback label)
  int get calendarWeekNumber {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Friendly week label: shows sequential week if available, else calendar week
  String weekLabel(int totalScans, int scanIndex) {
    if (weekIndex > 0) return 'Week $weekIndex';
    // Fallback: reverse index (first scan = Week 1)
    return 'Week ${totalScans - scanIndex}';
  }

  static String computeRating(double aura) {
    if (aura >= 85) return 'Legendary';
    if (aura >= 72) return 'Elite';
    if (aura >= 58) return 'Rising';
    return 'Developing';
  }

  /// Build from a Firestore document data.
  factory ScanRecord.fromFirestore(Map<String, dynamic> data) {
    DateTime d;
    if (data['scan_date'] is Timestamp) {
      d = (data['scan_date'] as Timestamp).toDate();
    } else {
      d = DateTime.parse(data['scan_date'].toString());
    }

    return ScanRecord(
      id:           data['id'] as String,
      date:         d,
      auraScore:    ((data['aura_score'] as num?) ?? 0).toDouble() * 10, // Convert 0-10 scale back to 0-100 for display
      jawlineScore: ((data['symmetry_score'] as num?) ?? 0).toDouble(),
      skinScore:    ((data['skin_details']?['texture'] as num?) ?? 0).toDouble(),
      eyeScore:     ((data['eye_details']?['alertness'] as num?) ?? 0).toDouble(),
      postureScore: ((data['posture_score'] as num?) ?? 0).toDouble(),
      
      // Comprehensive metrics
      faceShape:          data['face_shape'] as String? ?? 'Oval',
      faceSymmetry:       ((data['face_symmetry'] as num?) ?? 0).toDouble(),
      skinHealthScore:    ((data['skin_health_score'] as num?) ?? 0).toDouble(),
      acneDetection:      data['acne_detection'] as String? ?? 'Clear',
      faceAgeEstimation:  (data['face_age_estimation'] as num?)?.toInt() ?? 20,
      darkCircles:        data['dark_circles'] as String? ?? 'None',
      hairDensity:        ((data['hair_density'] as num?) ?? 0).toDouble(),
      overallAiFaceScore: ((data['overall_ai_face_score'] as num?) ?? 0).toDouble(),

      rating:       data['rating'] as String? ?? '',
      highlights:   List<String>.from(data['highlights'] ?? []),
      imageUrl:     data['image_url'] as String?,
      weekIndex:    (data['week_index'] as int?) ?? 0,
      fullData:     data,
      isSynced:     true,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Reads and writes scan records via SQLite (local-first).
/// Firestore sync is handled separately by SyncService.
class ScanHistoryNotifier extends StateNotifier<List<ScanRecord>> {
  ScanHistoryNotifier() : super([]) {
    loadHistory();
  }

  final FirestoreService _firestore = FirestoreService();

  Future<void> loadHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final docs = await _firestore.getUserScans(userId);
      state = docs.map(ScanRecord.fromFirestore).toList();
    } catch (e) {
      state = [];
    }
  }

  // Direct Firestore saving is handled by ScanningProcessScreen synchronously.
  // After saving, loadHistory() is called to refresh state.

  void mergeImported(List<ScanRecord> imported) {
    if (imported.isEmpty) return;
    final existingIds = state.map((s) => s.id).toSet();
    final newRecords  = imported.where((r) => !existingIds.contains(r.id));
    final merged      = [...state, ...newRecords];
    merged.sort((a, b) => b.date.compareTo(a.date)); // newest first
    state = merged;
  }

  /// No-op kept for API compatibility (seeding disabled for production).
  Future<void> seedDemoData() async {}
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final scanHistoryProvider =
    StateNotifierProvider<ScanHistoryNotifier, List<ScanRecord>>((ref) {
  // SQLite is self-contained; no SharedPreferences dependency needed.
  // We still watch sharedPreferencesProvider so the provider is available
  // in the same scope, but we don't pass it.
  ref.watch(sharedPreferencesProvider); // ensure prefs are initialised first
  return ScanHistoryNotifier();
});
