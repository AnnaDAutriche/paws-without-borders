class Animal {
  final String id;
  final String shelterId;

  /// Record lifecycle status.
  ///
  /// Firestore field: `record_status`.
  /// Values: `active`, `removed`, `suspended`.
  final String recordStatus;
  final String name;
  final String description;
  /// Primary image (first image).
  final String imageUrl;

  /// Optional gallery images. For cost control we cap at 2 total images.
  ///
  /// Firestore field: `image_urls`.
  final List<String> imageUrls;
  final String age;
  final String gender;

  /// Adoption/listing state shown in the UI (e.g. available/adopted).
  ///
  /// Firestore field: `status` (legacy) and `adoption_status` (forward-compatible).
  final String status;
  final String breed;
  final String weight;
  final DateTime createdAt;
  final DateTime updatedAt;

  Animal({
    required this.id,
    required this.shelterId,
    this.recordStatus = 'active',
    required this.name,
    required this.description,
    required this.imageUrl,
    List<String>? imageUrls,
    required this.age,
    required this.gender,
    required this.status,
    required this.breed,
    required this.weight,
    required this.createdAt,
    required this.updatedAt,
  }) : imageUrls = imageUrls ?? _normalizeUrls(imageUrl, const []);

  /// Returns the best available image URL with the following priority:
  /// 1) `image_url` (imageUrl)
  /// 2) first item of `image_urls` (imageUrls[0])
  ///
  /// This is intentionally resilient to partially-migrated Firestore documents.
  String get photoUrl {
    final primary = imageUrl.trim();
    if (primary.isNotEmpty) return primary;
    if (imageUrls.isNotEmpty) return imageUrls.first.trim();
    return '';
  }

  /// Normalized gallery URLs (deduped, trimmed, capped to 2).
  ///
  /// Includes [imageUrl] as the first item when present.
  List<String> get galleryUrls => _normalizeUrls(imageUrl, imageUrls);

  static List<String> _normalizeUrls(String primary, List<String> urls) {
    final cleaned = <String>[];
    void add(String u) {
      final t = u.trim();
      if (t.isEmpty) return;
      if (!cleaned.contains(t)) cleaned.add(t);
    }

    add(primary);
    for (final u in urls) add(u);
    if (cleaned.length > 2) return cleaned.sublist(0, 2);
    return cleaned;
  }

  Map<String, dynamic> toJson() {
    final normalized = _normalizeUrls(imageUrl, imageUrls);
    final primary = imageUrl.trim().isNotEmpty
        ? imageUrl.trim()
        : (normalized.isNotEmpty ? normalized.first : '');
    return {
      // IMPORTANT: Do NOT store the Firestore document id inside the document.
      // The id is derived from the DocumentSnapshot id.
      'shelter_id': shelterId,
      'record_status': recordStatus,
      'name': name,
      'description': description,
      // Keep both fields for backward compatibility.
      // Always persist the first image as `image_url`.
      'image_url': primary,
      'image_urls': normalized,
      'age': age,
      'gender': gender,
      // Keep legacy `status` for compatibility with existing UI + data.
      'status': status,
      // Also persist a forward-compatible adoption field.
      'adoption_status': status,
      'breed': breed,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Animal.fromJson({required String id, required Map<String, dynamic> json}) {
    final urls = (json['image_urls'] is List)
        ? (json['image_urls'] as List).map((e) => (e ?? '').toString()).toList()
        : <String>[];
    var primary = (json['image_url'] ?? json['photoUrl'] ?? '').toString();
    if (primary.trim().isEmpty && urls.isNotEmpty) primary = urls.first.toString();

    final recordStatusRaw = (json['record_status'] ?? 'active').toString().toLowerCase();
    final recordStatus = (recordStatusRaw == 'removed' || recordStatusRaw == 'suspended' || recordStatusRaw == 'active')
        ? recordStatusRaw
        : 'active';

    // Backward/forward compatibility:
    // - Old docs: `status` == available/adopted
    // - New docs: `adoption_status` == available/adopted
    final adoption = (json['adoption_status'] ?? json['status'] ?? '').toString();

    return Animal(
      id: id,
      shelterId: (json['shelter_id'] ?? json['shelterId'] ?? '').toString(),
      recordStatus: recordStatus,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: primary,
      imageUrls: urls,
      age: (json['age'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      status: adoption,
      breed: (json['breed'] ?? '').toString(),
      weight: (json['weight'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Animal copyWith({
    String? id,
    String? shelterId,
    String? recordStatus,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    String? age,
    String? gender,
    String? status,
    String? breed,
    String? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Animal(
    id: id ?? this.id,
    shelterId: shelterId ?? this.shelterId,
    recordStatus: recordStatus ?? this.recordStatus,
    name: name ?? this.name,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    imageUrls: imageUrls ?? this.imageUrls,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    status: status ?? this.status,
    breed: breed ?? this.breed,
    weight: weight ?? this.weight,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
