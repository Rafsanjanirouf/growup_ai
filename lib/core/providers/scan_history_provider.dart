import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_db_service.dart';
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

  /// Build from a SQLite row map.
  factory ScanRecord.fromSqlite(Map<String, dynamic> row) => ScanRecord(
        id:           row['id'] as String,
        date:         DateTime.parse(row['date'] as String),
        auraScore:    (row['aura_score'] as num).toDouble(),
        jawlineScore: (row['jawline_score'] as num).toDouble(),
        skinScore:    (row['skin_score'] as num).toDouble(),
        eyeScore:     (row['eye_score'] as num).toDouble(),
        postureScore: (row['posture_score'] as num).toDouble(),
        rating:       row['rating'] as String,
        highlights:   LocalDbService.parseHighlights(row['highlights']),
        imageUrl:     row['image_url'] as String?,
        weekIndex:    (row['week_index'] as int?) ?? 0,
        fullData:     row['full_data'] != null ? _parseFullData(row['full_data'] as String) : null,
        isSynced:     (row['is_synced'] as int? ?? 0) == 1,
      );

  static Map<String, dynamic>? _parseFullData(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Reads and writes scan records via SQLite (local-first).
/// Firestore sync is handled separately by SyncService.
class ScanHistoryNotifier extends StateNotifier<List<ScanRecord>> {
  ScanHistoryNotifier() : super([]) {
    loadHistory();
  }

  final LocalDbService _localDb = LocalDbService();

  Future<void> loadHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final rows = await _localDb.getAllScans(userId);
      state = rows.map(ScanRecord.fromSqlite).toList();
    } catch (e) {
      state = [];
    }
  }

  /// Insert a new scan into SQLite immediately (local-first).
  /// Pass [fullData] so SyncService can later push the full Gemini payload.
  Future<void> addScan(
    ScanRecord record, {
    Map<String, dynamic>? fullData,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await _localDb.insertScan(
      id:           record.id,
      userId:       userId,
      date:         record.date,
      auraScore:    record.auraScore,
      jawlineScore: record.jawlineScore,
      skinScore:    record.skinScore,
      eyeScore:     record.eyeScore,
      postureScore: record.postureScore,
      rating:       record.rating,
      highlights:   record.highlights,
      imageUrl:     record.imageUrl,
      isSynced:     false,
      fullData:     fullData,
    );
    // Prepend to in-memory state (newest first) without re-reading DB
    state = [record, ...state];
  }

  /// Called by SyncService after remote records are imported.
  /// Merges them into state without duplicates.
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
