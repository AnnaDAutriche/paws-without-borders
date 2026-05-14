import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:paws_without_borders/models/review.dart';

class ReviewService {
  final FirebaseFirestore _db;

  ReviewService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('reviews');

  Stream<List<Review>> watchReviewsByShelterId(String shelterId) => _col
      .where('shelter_id', isEqualTo: shelterId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(_fromDoc).toList());

  Future<List<Review>> getReviewsByShelterId(String shelterId) async {
    try {
      final snap = await _col.where('shelter_id', isEqualTo: shelterId).orderBy('created_at', descending: true).get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('Failed to load reviews: $e');
      return [];
    }
  }

  Future<String?> addReview(Review review) async {
    try {
      final doc = _col.doc(review.id);
      await doc.set(_toFirestore(review), SetOptions(merge: false));
      return doc.id;
    } catch (e) {
      debugPrint('Failed to add review: $e');
      return null;
    }
  }

  Review _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Review(
      id: doc.id,
      shelterId: (data['shelter_id'] ?? '') as String,
      userId: (data['user_id'] ?? '') as String,
      userName: (data['user_name'] ?? '') as String,
      rating: (data['rating'] ?? 0) is num ? ((data['rating'] ?? 0) as num).toDouble() : 0,
      comment: (data['comment'] ?? '') as String,
      createdAt: _asDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _asDateTime(data['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toFirestore(Review r) => {
        'shelter_id': r.shelterId,
        'user_id': r.userId,
        'user_name': r.userName,
        'rating': r.rating,
        'comment': r.comment,
        'created_at': Timestamp.fromDate(r.createdAt),
        'updated_at': Timestamp.fromDate(r.updatedAt),
      };

  DateTime? _asDateTime(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
