
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

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

  factory OutfitRecord.fromFirestore(Map<String, dynamic> data) {
    DateTime d;
    if (data['date'] is Timestamp) {
      d = (data['date'] as Timestamp).toDate();
    } else {
      d = DateTime.parse(data['date'].toString());
    }

    return OutfitRecord(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      date: d,
      imagePath: data['image_url'] as String?,
      fullData: data['full_data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class OutfitHistoryNotifier extends StateNotifier<List<OutfitRecord>> {
  OutfitHistoryNotifier() : super([]) {
    loadHistory();
  }

  final FirestoreService _firestore = FirestoreService();

  Future<void> loadHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final docs = await _firestore.getOutfitScans(userId);
      state = docs.map(OutfitRecord.fromFirestore).toList();
    } catch (e) {
      state = [];
    }
  }

  Future<void> addOutfitScan(OutfitRecord record) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore.saveOutfitRecord(
      id: record.id,
      userId: userId,
      date: record.date,
      imageUrl: record.imagePath,
      fullData: record.fullData,
    );
    state = [record, ...state];
  }

  Future<void> deleteOutfitScan(String id) async {
    await _firestore.deleteOutfitRecord(id);
    state = state.where((record) => record.id != id).toList();
  }
}

final outfitHistoryProvider =
    StateNotifierProvider<OutfitHistoryNotifier, List<OutfitRecord>>((ref) {
  return OutfitHistoryNotifier();
});
