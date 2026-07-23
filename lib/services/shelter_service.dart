import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/services/image_upload_optimizer.dart';

class ShelterService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ShelterService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('shelters');

  /// Strict public visibility:
  /// - requires the lifecycle field to exist
  /// - requires it to be exactly 'active' (case-insensitive)
  ///
  /// This intentionally treats legacy docs missing `status` as NOT public.
  bool _isPublicShelterData(Map<String, dynamic> data) {
    final v = data['status'];
    return v is String && v.trim().toLowerCase() == 'active';
  }

 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paws_without_borders/models/shelter.dart';
import 'package:paws_without_borders/services/image_upload_optimizer.dart';

class ShelterService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ShelterService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('shelters');

  /// Strict public visibility:
  /// - requires the lifecycle field to exist
  /// - requires it to be exactly 'active' (case-insensitive)
  ///
  /// This intentionally treats legacy docs missing `status` as NOT public.
  bool _isPublicShelterData(Map<String, dynamic> data) {
    final v = data['status'];
    return v is String && v.trim().toLowerCase() == 'active';
  }

  /// Public stream of shelters (hides removed/suspended).
Stream<List<Shelter>> watchShelters() => _col
    .orderBy('created_at', descending: true)
    .snapshots()
    .map(
      (snap) => snap.docs
          .where((d) => _isPublicShelterData(d.data()))
          .map(_fromDoc)
          .toList(),
    );

/// Admin only: pending shelters waiting for approval.
Stream<List<Shelter>> watchPendingShelters() => _col
    .where('status', isEqualTo: 'pending')
    .snapshots()
    .map(
      (snap) => snap.docs.map(_fromDoc).toList(),
    );

/// Public watch by id (returns null for removed/suspended).
Stream<Shelter?> watchShelterById(String id) => _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() ?? const <String, dynamic>{};
      if (!_isPublicShelterData(data)) return null;
      return _fromDoc(doc);
    });
  Future<List<Shelter>> getShelters() async {
    try {
      final snap = await _col.orderBy('created_at', descending: true).get();
      return snap.docs
          .where((d) => _isPublicShelterData(d.data()))
          .map(_fromDoc)
          .toList();
    } catch (e) {
      debugPrint('Failed to load shelters: $e');
      return [];
    }
  }

  Future<Shelter?> getShelterById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? const <String, dynamic>{};
      if (!_isPublicShelterData(data)) return null;
      return _fromDoc(doc);
    } catch (e) {
      debugPrint('Failed to load shelter by id: $e');
      return null;
    }
  }

  Future<Shelter?> getShelterByOwnerId(String ownerId) async {
    try {
      final snap = await _col.where('owner_id', isEqualTo: ownerId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return _fromDoc(snap.docs.first);
    } catch (e) {
      debugPrint('Failed to load shelter by owner id: $e');
      return null;
    }
  }

  Future<String?> addShelter(Shelter shelter) async {
    try {
      final doc = _col.doc(shelter.id);
      await doc.set(_toFirestore(shelter), SetOptions(merge: false));
      return doc.id;
    } catch (e) {
      debugPrint('Failed to add shelter: $e');
      return null;
    }
  }

  Future<void> updateShelter(Shelter shelter) async {
    try {
      await _col.doc(shelter.id).set(_toFirestore(shelter), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update shelter: $e');
    }
  }

  Future<void> deleteShelter(String id) async {
    try {
      // Soft delete: never remove the document.
      await _col.doc(id).set({'status': 'removed', 'updated_at': Timestamp.now()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to delete shelter: $e');
    }
  }

  /// Uploads a single shelter image to Storage and returns its download URL.
  ///
  /// Path: `shelters/{shelterId}.jpg`
  ///
  /// Image is always optimized before upload (no original full-size upload).
  Future<String> uploadShelterImage({required String shelterId, required XFile file}) async {
    try {
      final originalBytes = await file.readAsBytes();
      final optimized = await ImageUploadOptimizer.optimize(originalBytes);

      final path = 'shelters/$shelterId.jpg';
      final ref = _storage.ref().child(path);
      await ref.putData(optimized, SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Failed to upload shelter image (FirebaseException): ${e.code} ${e.message}');
      throw ShelterImageUploadFailure(_firebaseStorageUserMessage(e));
    } on ImageUploadException catch (e) {
      debugPrint('Failed to optimize shelter image: $e');
      throw ShelterImageUploadFailure(_optimizerUserMessage(e));
    } catch (e) {
      debugPrint('Failed to upload shelter image: $e');
      throw const ShelterImageUploadFailure('Upload failed. Please try again.');
    }
  }

  String _firebaseStorageUserMessage(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Upload not allowed (Storage rules). Please sign in and ensure you own this shelter.';
      case 'canceled':
        return 'Upload canceled.';
      case 'retry-limit-exceeded':
      case 'quota-exceeded':
        return 'Upload temporarily unavailable. Please try again later.';
      default:
        return 'Upload failed (${e.code}). Please try again.';
    }
  }

  String _optimizerUserMessage(ImageUploadException e) {
    switch (e.error) {
      case ImageUploadError.tooLarge:
        return 'Image too large (max 1MB).';
      case ImageUploadError.decodeFailed:
        return 'Could not read this image. Try a different file.';
      case ImageUploadError.cannotMeetSizeBudget:
        return 'Image can\'t be compressed under 500KB. Please pick a smaller photo.';
    }
  }

  Shelter _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Shelter(
      id: doc.id,
      status: (data['status'] ?? 'active') as String,
      name: (data['name'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      whatsapp: (data['whatsapp'] ?? '') as String,
      telegram: (data['telegram'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      instagram: (data['instagram'] ?? '') as String,
      paypal: (data['paypal'] ?? '') as String,
      internationalDelivery: (data['international_delivery'] ?? false) as bool,
      ownerId: (data['owner_id'] ?? '') as String,
      imageUrl: (data['image_url'] ?? '') as String,
      galleryImages: List<String>.from((data['gallery_images'] ?? const <dynamic>[]) as List),
      rating: (data['rating'] ?? 0) is num ? ((data['rating'] ?? 0) as num).toDouble() : 0,
      createdAt: _asDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _asDateTime(data['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toFirestore(Shelter s) => {
        'status': s.status,
        'name': s.name,
        'location': s.location,
        'description': s.description,
        'whatsapp': s.whatsapp,
        'telegram': s.telegram,
        'email': s.email,
        'instagram': s.instagram,
        'paypal': s.paypal,
        'international_delivery': s.internationalDelivery,
        'owner_id': s.ownerId,
        'image_url': s.imageUrl,
        'gallery_images': s.galleryImages,
        'rating': s.rating,
        'created_at': Timestamp.fromDate(s.createdAt),
        'updated_at': Timestamp.fromDate(s.updatedAt),
      };

  DateTime? _asDateTime(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class ShelterImageUploadFailure implements Exception {
  final String message;
  const ShelterImageUploadFailure(this.message);

  @override
  String toString() => 'ShelterImageUploadFailure($message)';
}

  Future<List<Shelter>> getShelters() async {
    try {
      final snap = await _col.orderBy('created_at', descending: true).get();
      return snap.docs
          .where((d) => _isPublicShelterData(d.data()))
          .map(_fromDoc)
          .toList();
    } catch (e) {
      debugPrint('Failed to load shelters: $e');
      return [];
    }
  }

  Future<Shelter?> getShelterById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? const <String, dynamic>{};
      if (!_isPublicShelterData(data)) return null;
      return _fromDoc(doc);
    } catch (e) {
      debugPrint('Failed to load shelter by id: $e');
      return null;
    }
  }

  Future<Shelter?> getShelterByOwnerId(String ownerId) async {
    try {
      final snap = await _col.where('owner_id', isEqualTo: ownerId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return _fromDoc(snap.docs.first);
    } catch (e) {
      debugPrint('Failed to load shelter by owner id: $e');
      return null;
    }
  }

  Future<String?> addShelter(Shelter shelter) async {
    try {
      final doc = _col.doc(shelter.id);
      await doc.set(_toFirestore(shelter), SetOptions(merge: false));
      return doc.id;
    } catch (e) {
      debugPrint('Failed to add shelter: $e');
      return null;
    }
  }

  Future<void> updateShelter(Shelter shelter) async {
    try {
      await _col.doc(shelter.id).set(_toFirestore(shelter), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update shelter: $e');
    }
  }

  Future<void> deleteShelter(String id) async {
    try {
      // Soft delete: never remove the document.
      await _col.doc(id).set({'status': 'removed', 'updated_at': Timestamp.now()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to delete shelter: $e');
    }
  }

  /// Uploads a single shelter image to Storage and returns its download URL.
  ///
  /// Path: `shelters/{shelterId}.jpg`
  ///
  /// Image is always optimized before upload (no original full-size upload).
  Future<String> uploadShelterImage({required String shelterId, required XFile file}) async {
    try {
      final originalBytes = await file.readAsBytes();
      final optimized = await ImageUploadOptimizer.optimize(originalBytes);

      final path = 'shelters/$shelterId.jpg';
      final ref = _storage.ref().child(path);
      await ref.putData(optimized, SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Failed to upload shelter image (FirebaseException): ${e.code} ${e.message}');
      throw ShelterImageUploadFailure(_firebaseStorageUserMessage(e));
    } on ImageUploadException catch (e) {
      debugPrint('Failed to optimize shelter image: $e');
      throw ShelterImageUploadFailure(_optimizerUserMessage(e));
    } catch (e) {
      debugPrint('Failed to upload shelter image: $e');
      throw const ShelterImageUploadFailure('Upload failed. Please try again.');
    }
  }

  String _firebaseStorageUserMessage(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Upload not allowed (Storage rules). Please sign in and ensure you own this shelter.';
      case 'canceled':
        return 'Upload canceled.';
      case 'retry-limit-exceeded':
      case 'quota-exceeded':
        return 'Upload temporarily unavailable. Please try again later.';
      default:
        return 'Upload failed (${e.code}). Please try again.';
    }
  }

  String _optimizerUserMessage(ImageUploadException e) {
    switch (e.error) {
      case ImageUploadError.tooLarge:
        return 'Image too large (max 1MB).';
      case ImageUploadError.decodeFailed:
        return 'Could not read this image. Try a different file.';
      case ImageUploadError.cannotMeetSizeBudget:
        return 'Image can\'t be compressed under 500KB. Please pick a smaller photo.';
    }
  }

  Shelter _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Shelter(
      id: doc.id,
      status: (data['status'] ?? 'active') as String,
      name: (data['name'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      whatsapp: (data['whatsapp'] ?? '') as String,
      telegram: (data['telegram'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      instagram: (data['instagram'] ?? '') as String,
      paypal: (data['paypal'] ?? '') as String,
      internationalDelivery: (data['international_delivery'] ?? false) as bool,
      ownerId: (data['owner_id'] ?? '') as String,
      imageUrl: (data['image_url'] ?? '') as String,
      galleryImages: List<String>.from((data['gallery_images'] ?? const <dynamic>[]) as List),
      rating: (data['rating'] ?? 0) is num ? ((data['rating'] ?? 0) as num).toDouble() : 0,
      createdAt: _asDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _asDateTime(data['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toFirestore(Shelter s) => {
        'status': s.status,
        'name': s.name,
        'location': s.location,
        'description': s.description,
        'whatsapp': s.whatsapp,
        'telegram': s.telegram,
        'email': s.email,
        'instagram': s.instagram,
        'paypal': s.paypal,
        'international_delivery': s.internationalDelivery,
        'owner_id': s.ownerId,
        'image_url': s.imageUrl,
        'gallery_images': s.galleryImages,
        'rating': s.rating,
        'created_at': Timestamp.fromDate(s.createdAt),
        'updated_at': Timestamp.fromDate(s.updatedAt),
      };

  DateTime? _asDateTime(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class ShelterImageUploadFailure implements Exception {
  final String message;
  const ShelterImageUploadFailure(this.message);

  @override
  String toString() => 'ShelterImageUploadFailure($message)';
}
