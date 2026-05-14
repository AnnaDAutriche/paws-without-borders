import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paws_without_borders/models/animal.dart';
import 'package:paws_without_borders/services/image_upload_optimizer.dart';

class AnimalService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  AnimalService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('animals');

  /// Strict public visibility for animals:
  /// - requires record_status field to exist
  /// - requires it to be exactly 'active' (case-insensitive)
  ///
  /// Legacy docs missing `record_status` are treated as NOT public.
  bool _isPublicAnimalData(Map<String, dynamic> data) {
    final v = data['record_status'];
    return v is String && v.trim().toLowerCase() == 'active';
  }

  bool _isPublicShelterData(Map<String, dynamic> data) {
    final v = data['status'];
    return v is String && v.trim().toLowerCase() == 'active';
  }

  Stream<T> _combineLatest2<A, B, T>(
    Stream<A> a,
    Stream<B> b,
    T Function(A a, B b) combiner,
  ) {
    late final StreamController<T> controller;
    A? lastA;
    B? lastB;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;

    controller = StreamController<T>(
      onListen: () {
        subA = a.listen(
          (value) {
            lastA = value;
            final aa = lastA;
            final bb = lastB;
            if (aa != null && bb != null) controller.add(combiner(aa, bb));
          },
          onError: controller.addError,
        );
        subB = b.listen(
          (value) {
            lastB = value;
            final aa = lastA;
            final bb = lastB;
            if (aa != null && bb != null) controller.add(combiner(aa, bb));
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }

  /// Public stream of animals (hides removed/suspended).
  Stream<List<Animal>> watchAnimalsByShelterId(String shelterId) {
    final animalsStream = _col.where('shelter_id', isEqualTo: shelterId).orderBy('created_at', descending: true).snapshots();
    final shelterStream = _db.collection('shelters').doc(shelterId).snapshots();
    return _combineLatest2<QuerySnapshot<Map<String, dynamic>>, DocumentSnapshot<Map<String, dynamic>>, List<Animal>>(
      animalsStream,
      shelterStream,
      (animalsSnap, shelterDoc) {
        final shelterData = shelterDoc.data() ?? const <String, dynamic>{};
        if (!shelterDoc.exists || !_isPublicShelterData(shelterData)) return const <Animal>[];

        return animalsSnap.docs
            .where((d) => _isPublicAnimalData(d.data()))
            .map(_fromDoc)
            .toList();
      },
    );
  }

  /// Public stream across all shelters.
  ///
  /// An animal is visible ONLY if:
  /// - animals.record_status == 'active'
  /// - owning shelters.status == 'active'
  Stream<List<Animal>> watchAllAnimals() {
    final animalsStream = _col.snapshots();
    final sheltersStream = _db.collection('shelters').snapshots();
    return _combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, List<Animal>>(
      animalsStream,
      sheltersStream,
      (animalsSnap, sheltersSnap) {
        final activeShelterIds = <String>{};
        for (final d in sheltersSnap.docs) {
          final data = d.data();
          if (_isPublicShelterData(data)) activeShelterIds.add(d.id);
        }
        return animalsSnap.docs
            .where((d) {
              final data = d.data();
              if (!_isPublicAnimalData(data)) return false;
              final sid = _asString(data['shelter_id']).trim();
              return sid.isNotEmpty && activeShelterIds.contains(sid);
            })
            .map(_fromDoc)
            .toList();
      },
    );
  }

  Stream<Animal?> watchAnimalById(String id) => _col.doc(id).snapshots().asyncExpand((doc) {
        if (!doc.exists) return Stream<Animal?>.value(null);
        final data = doc.data() ?? const <String, dynamic>{};
        if (!_isPublicAnimalData(data)) return Stream<Animal?>.value(null);

        final shelterId = _asString(data['shelter_id']).trim();
        if (shelterId.isEmpty) return Stream<Animal?>.value(null);

        return _db.collection('shelters').doc(shelterId).snapshots().map((shelterDoc) {
          if (!shelterDoc.exists) return null;
          final shelterData = shelterDoc.data() ?? const <String, dynamic>{};
          if (!_isPublicShelterData(shelterData)) return null;
          return _fromDoc(doc);
        });
      });

  Future<List<Animal>> getAnimalsByShelterId(String shelterId) async {
    try {
      final shelterDoc = await _db.collection('shelters').doc(shelterId).get();
      if (!shelterDoc.exists || !_isPublicShelterData(shelterDoc.data() ?? const <String, dynamic>{})) return [];
      final snap = await _col.where('shelter_id', isEqualTo: shelterId).orderBy('created_at', descending: true).get();
      return snap.docs
          .where((d) => _isPublicAnimalData(d.data()))
          .map(_fromDoc)
          .toList();
    } catch (e) {
      debugPrint('Failed to load animals: $e');
      return [];
    }
  }

  Future<List<Animal>> getAllAnimals() async {
    try {
      final sheltersSnap = await _db.collection('shelters').get();
      final activeShelterIds = <String>{};
      for (final d in sheltersSnap.docs) {
        final data = d.data();
        if (_isPublicShelterData(data)) activeShelterIds.add(d.id);
      }

      final snap = await _col.get();
      return snap.docs
          .where((d) {
            final data = d.data();
            if (!_isPublicAnimalData(data)) return false;
            final sid = _asString(data['shelter_id']).trim();
            return sid.isNotEmpty && activeShelterIds.contains(sid);
          })
          .map(_fromDoc)
          .toList();
    } catch (e) {
      debugPrint('Failed to load all animals: $e');
      return [];
    }
  }

  Future<Animal?> getAnimalById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? const <String, dynamic>{};
      if (!_isPublicAnimalData(data)) return null;
      final shelterId = _asString(data['shelter_id']).trim();
      if (shelterId.isEmpty) return null;

      final shelterDoc = await _db.collection('shelters').doc(shelterId).get();
      if (!shelterDoc.exists || !_isPublicShelterData(shelterDoc.data() ?? const <String, dynamic>{})) return null;
      return _fromDoc(doc);
    } catch (e) {
      debugPrint('Failed to load animal by id: $e');
      return null;
    }
  }

  Future<String?> addAnimal(Animal animal) async {
    try {
      final doc = _col.doc(animal.id);
      await doc.set(_toFirestore(animal), SetOptions(merge: false));
      return doc.id;
    } catch (e) {
      debugPrint('Failed to add animal: $e');
      return null;
    }
  }

  Future<void> updateAnimal(Animal animal) async {
    try {
      await _col.doc(animal.id).set(_toFirestore(animal), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update animal: $e');
    }
  }

  Future<void> deleteAnimal(String id) async {
    try {
      // Soft delete: never remove the document or Storage assets.
      await _col.doc(id).set({'record_status': 'removed', 'updated_at': Timestamp.now()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to delete animal: $e');
    }
  }

  /// Uploads an image to Storage and returns the download URL.
  Future<String> uploadAnimalImage({required String shelterId, required XFile file}) async {
    try {
      final originalBytes = await file.readAsBytes();
      final optimized = await ImageUploadOptimizer.optimize(originalBytes);

      final path = 'animals/$shelterId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(path);
      await ref.putData(optimized, SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=604800'));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Failed to upload image (FirebaseException): ${e.code} ${e.message}');
      throw ImageUploadFailure(_firebaseStorageUserMessage(e));
    } on ImageUploadException catch (e) {
      debugPrint('Failed to optimize image: $e');
      throw ImageUploadFailure(_optimizerUserMessage(e));
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      throw const ImageUploadFailure('Upload failed. Please try again.');
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

  Animal _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final urls = <String>[];
    final rawUrls = data['image_urls'];
    if (rawUrls is List) {
      for (final u in rawUrls) {
        final s = _asString(u).trim();
        if (s.isNotEmpty && !urls.contains(s)) urls.add(s);
      }
    }
    var primary = _asString(data['image_url']).trim();
    if (primary.isEmpty && urls.isNotEmpty) primary = urls.first;

    return Animal(
      id: doc.id,
      shelterId: _asString(data['shelter_id']),
      recordStatus: _asString(data['record_status']).isNotEmpty ? _asString(data['record_status']) : 'active',
      name: _asString(data['name']),
      description: _asString(data['description']),
      age: _asString(data['age']),
      imageUrl: primary,
      imageUrls: urls,
      // Backward/forward compatibility: prefer adoption_status, fallback to status.
      status: _asString(data['adoption_status']).isNotEmpty
          ? _asString(data['adoption_status'])
          : (_asString(data['status']).isNotEmpty ? _asString(data['status']) : 'available'),
      gender: _asString(data['gender']),
      breed: _asString(data['breed']),
      weight: _asString(data['weight']),
      createdAt: _asDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _asDateTime(data['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toFirestore(Animal a) => {
        'shelter_id': a.shelterId,
        'name': a.name,
        'description': a.description,
        'age': a.age,
        'image_url': a.imageUrls.isNotEmpty ? a.imageUrls.first : a.imageUrl,
        'image_urls': a.imageUrls,
        'record_status': a.recordStatus,
        // Keep legacy `status` and also persist `adoption_status`.
        'status': a.status,
        'adoption_status': a.status,
        'gender': a.gender,
        'breed': a.breed,
        'weight': a.weight,
        'created_at': Timestamp.fromDate(a.createdAt),
        'updated_at': Timestamp.fromDate(a.updatedAt),
      };

  DateTime? _asDateTime(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _asString(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}

class ImageUploadFailure implements Exception {
  final String message;
  const ImageUploadFailure(this.message);

  @override
  String toString() => 'ImageUploadFailure($message)';
}
