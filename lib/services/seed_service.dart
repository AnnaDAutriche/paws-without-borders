import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin-only helper to populate Firestore with coherent sample data.
///
/// Uses fixed document IDs so cross-references (animals/reviews -> shelter_id)
/// are always valid.
class SeedService {
  final FirebaseFirestore _db;

  SeedService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const String sampleShelterId1 = 'sample_shelter_1';
  static const String sampleShelterId2 = 'sample_shelter_2';

  static const String _seedMetaCollection = 'meta';
  static const String _seedStateDocId = 'seed_state';

  DocumentReference<Map<String, dynamic>> get _seedStateRef => _db.collection(_seedMetaCollection).doc(_seedStateDocId);

  Future<void> seedForUser({required String uid, required String email}) async {
    try {
      // Hard-block seeding in non-debug builds. UI gating alone is not sufficient.
      if (!kDebugMode) {
        debugPrint('Seed blocked: not in debug mode.');
        return;
      }

      final cleanedEmail = email.trim();
      if (uid.trim().isEmpty) {
        throw ArgumentError('uid is required');
      }
      if (cleanedEmail.isEmpty) {
        throw ArgumentError('email is required');
      }

      // Global seed guard (not user-scoped): once meta/seed_state.seeded == true,
      // sample data must never be re-created again regardless of which admin is signed in.
      //
      // We use a transaction so the check + write is as atomic as Firestore allows.
      await _db.runTransaction((tx) async {
        final seedStateSnap = await tx.get(_seedStateRef);
        final seeded = seedStateSnap.data()?['seeded'] == true;
        if (seeded) {
          throw StateError('Sample data seeding is globally locked (meta/seed_state.seeded == true).');
        }

        final now = Timestamp.now();

        // Ensure a user profile doc exists at users/{uid}.
        tx.set(
          _db.collection('users').doc(uid),
          {
            'email': cleanedEmail,
            'name': cleanedEmail.split('@').first,
            'created_at': now,
            'updated_at': now,
          },
          SetOptions(merge: true),
        );

        // Shelters
        tx.set(
          _db.collection('shelters').doc(sampleShelterId1),
          {
            'status': 'active',
            'name': 'Paws Without Borders — Kyiv Hub',
            'location': 'Kyiv, Ukraine',
            'description': 'A small, volunteer-run hub focused on emergency foster placements, vet support, and cross-border coordination.',
            'whatsapp': '+380000000001',
            'telegram': '@pwb_kyiv',
            'email': cleanedEmail,
            'instagram': 'https://instagram.com/pawswithoutborders',
            'paypal': 'https://paypal.me/pawswithoutborders',
            'international_delivery': true,
            'owner_id': uid,
            'image_url': 'assets/images/modern_animal_shelter_building_garden_null_1774856280912.jpg',
            'gallery_images': [
              'assets/images/animal_shelter_interior_clean_null_1774856286081.jpg',
              'assets/images/happy_dog_in_shelter_kennel_null_1774856281772.jpg',
            ],
            'rating': 4.8,
            'created_at': now,
            'updated_at': now,
          },
        );

        tx.set(
          _db.collection('shelters').doc(sampleShelterId2),
          {
            'status': 'active',
            'name': 'Green Haven Shelter',
            'location': 'Lviv, Ukraine',
            'description': 'Partner shelter with a strong adoption network and weekly transport to EU foster homes.',
            'whatsapp': '+380000000002',
            'telegram': '@greenhaven_lviv',
            'email': 'contact@greenhaven.example',
            'instagram': 'https://instagram.com/greenhaven',
            'paypal': 'https://paypal.me/greenhaven',
            'international_delivery': true,
            'owner_id': uid,
            'image_url': 'assets/images/animal_shelter_interior_clean_null_1774856286081.jpg',
            'gallery_images': [
              'assets/images/cat_shelter_cage_null_1774856286832.jpg',
              'assets/images/ginger_kitten_playing_null_1774856283479.jpg',
            ],
            'rating': 4.6,
            'created_at': now,
            'updated_at': now,
          },
        );

        // Animals
        tx.set(
          _db.collection('animals').doc('sample_animal_1'),
          {
            'shelter_id': sampleShelterId1,
            'record_status': 'active',
            'name': 'Milo',
            'description': 'Friendly, calm, and great with other dogs. Loves gentle walks and treats.',
            'age': '2 years',
            'image_url': 'assets/images/border_collie_dog_null_1774856284410.jpg',
            'status': 'available',
            'gender': 'Male',
            'breed': 'Border Collie mix',
            'weight': '18 kg',
            'created_at': now,
            'updated_at': now,
          },
        );

        tx.set(
          _db.collection('animals').doc('sample_animal_2'),
          {
            'shelter_id': sampleShelterId1,
            'record_status': 'active',
            'name': 'Nala',
            'description': 'Playful puppy with a big heart. Still learning leash manners.',
            'age': '6 months',
            'image_url': 'assets/images/cute_golden_retriever_puppy_null_1774856282668.jpg',
            'status': 'available',
            'gender': 'Female',
            'breed': 'Retriever mix',
            'weight': '9 kg',
            'created_at': now,
            'updated_at': now,
          },
        );

        tx.set(
          _db.collection('animals').doc('sample_animal_3'),
          {
            'shelter_id': sampleShelterId2,
            'record_status': 'active',
            'name': 'Luna',
            'description': 'Gentle cat, litter-trained, enjoys quiet corners and soft blankets.',
            'age': '1 year',
            'image_url': 'assets/images/ginger_kitten_playing_null_1774856283479.jpg',
            'status': 'available',
            'gender': 'Female',
            'breed': 'Domestic short hair',
            'weight': '3.5 kg',
            'created_at': now,
            'updated_at': now,
          },
        );

        tx.set(
          _db.collection('animals').doc('sample_animal_4'),
          {
            'shelter_id': sampleShelterId2,
            'record_status': 'active',
            'name': 'Ghost',
            'description': 'Bright eyes, very smart, and loves running. Best in an active family.',
            'age': '3 years',
            'image_url': 'assets/images/husky_dog_blue_eyes_null_1774856285081.jpg',
            'status': 'available',
            'gender': 'Male',
            'breed': 'Husky',
            'weight': '22 kg',
            'created_at': now,
            'updated_at': now,
          },
        );

        // Reviews (all authored by the signed-in user for simplicity).
        tx.set(
          _db.collection('reviews').doc('sample_review_1'),
          {
            'shelter_id': sampleShelterId1,
            'user_id': uid,
            'user_name': 'Anna',
            'rating': 5,
            'comment': 'Quick responses, transparent updates, and very caring volunteers.',
            'created_at': now,
            'updated_at': now,
          },
        );

        tx.set(
          _db.collection('reviews').doc('sample_review_2'),
          {
            'shelter_id': sampleShelterId2,
            'user_id': uid,
            'user_name': 'Anna',
            'rating': 4.5,
            'comment': 'Clean facility and well-organized adoption process.',
            'created_at': now,
            'updated_at': now,
          },
        );

        // Mark global seed state as completed.
        tx.set(
          _seedStateRef,
          {
            'seeded': true,
            'seeded_at': now,
            'seeded_by_uid': uid,
            'seeded_by_email': cleanedEmail,
            'updated_at': now,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      debugPrint('Seed failed: $e');
      rethrow;
    }
  }
}
