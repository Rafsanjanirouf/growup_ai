import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_db_service.dart';

class OutfitRecord {
  final String id;
  final String userId;
  final DateTime date;
  final String? imagePath;
  final Map<String, dynamic> fullData;

  OutfitRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.imagePath,
    required this.fullData,
  });

  factory OutfitRecord.fromSqlite(Map<String, dynamic> row) {
    return OutfitRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      date: DateTime.parse(row['date'] as String),
      imagePath: row['image_path'] as String?,
      fullData: jsonDecode(row['full_data'] as String) as Map<String, dynamic>,
    );
  }
}

class OutfitHistoryNotifier extends StateNotifier<List<OutfitRecord>> {
  OutfitHistoryNotifier() : super([]) {
    loadHistory();
  }

  final LocalDbService _localDb = LocalDbService();

  Future<void> loadHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final rows = await _localDb.getAllOutfitScans(userId);
      state = rows.map(OutfitRecord.fromSqlite).toList();
    } catch (e) {
      state = [];
    }
  }

  Future<void> addOutfitScan(OutfitRecord record) async {
    await _localDb.insertOutfitScan(
      id: record.id,
      userId: record.userId,
      date: record.date,
      imagePath: record.imagePath,
      fullData: record.fullData,
    );
    state = [record, ...state];
  }

  Future<void> deleteOutfitScan(String id) async {
    await _localDb.deleteOutfitScan(id);
    state = state.where((record) => record.id != id).toList();
  }
}

final outfitHistoryProvider =
    StateNotifierProvider<OutfitHistoryNotifier, List<OutfitRecord>>((ref) {
  return OutfitHistoryNotifier();
});
