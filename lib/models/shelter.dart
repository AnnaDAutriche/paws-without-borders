class Shelter {
  final String id;
  /// Record lifecycle status.
  ///
  /// Firestore field: `status`.
  /// Values: `active`, `removed`, `suspended`.
  final String status;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final List<String> galleryImages;
  final double rating;
  final String email;
  final String whatsapp;
  final String telegram;
  final String instagram;
  final String paypal;
  final bool internationalDelivery;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shelter({
    required this.id,
    this.status = 'active',
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.galleryImages,
    required this.rating,
    required this.email,
    required this.whatsapp,
    required this.telegram,
    required this.instagram,
    required this.paypal,
    required this.internationalDelivery,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get paypalLink => paypal;

  Map<String, dynamic> toJson() => {
        // Keep a JSON representation compatible with our Firestore schema.
        // IMPORTANT: Do NOT store the Firestore document id inside the document.
        // The id is derived from the DocumentSnapshot id.
        'name': name,
        'status': status,
        'location': location,
        'description': description,
        'image_url': imageUrl,
        'gallery_images': galleryImages,
        'rating': rating,
        'email': email,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'instagram': instagram,
        'paypal': paypal,
        'international_delivery': internationalDelivery,
        'owner_id': ownerId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Shelter.fromJson({required String id, required Map<String, dynamic> json}) {
    final galleryRaw = json['gallery_images'] ?? json['galleryImages'] ?? const <dynamic>[];
    final createdRaw = json['created_at'] ?? json['createdAt'] ?? '';
    final updatedRaw = json['updated_at'] ?? json['updatedAt'] ?? '';
    return Shelter(
      id: id,
      status: (json['status'] ?? 'active') as String,
      name: (json['name'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '') as String,
      galleryImages: (galleryRaw is List) ? galleryRaw.map((e) => (e ?? '').toString()).toList() : const <String>[],
      rating: (json['rating'] ?? 0) is num ? ((json['rating'] ?? 0) as num).toDouble() : 0,
      email: (json['email'] ?? '') as String,
      whatsapp: (json['whatsapp'] ?? '') as String,
      telegram: (json['telegram'] ?? '') as String,
      instagram: (json['instagram'] ?? '') as String,
      paypal: (json['paypal'] ?? json['paypalLink'] ?? '') as String,
      internationalDelivery: (json['international_delivery'] ?? false) as bool,
      ownerId: (json['owner_id'] ?? '') as String,
      createdAt: DateTime.tryParse(createdRaw.toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedRaw.toString()) ?? DateTime.now(),
    );
  }

  Shelter copyWith({
    String? id,
    String? status,
    String? name,
    String? location,
    String? description,
    String? imageUrl,
    List<String>? galleryImages,
    double? rating,
    String? email,
    String? whatsapp,
    String? telegram,
    String? instagram,
    String? paypal,
    bool? internationalDelivery,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Shelter(
    id: id ?? this.id,
    status: status ?? this.status,
    name: name ?? this.name,
    location: location ?? this.location,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    galleryImages: galleryImages ?? this.galleryImages,
    rating: rating ?? this.rating,
    email: email ?? this.email,
    whatsapp: whatsapp ?? this.whatsapp,
    telegram: telegram ?? this.telegram,
    instagram: instagram ?? this.instagram,
    paypal: paypal ?? this.paypal,
    internationalDelivery: internationalDelivery ?? this.internationalDelivery,
    ownerId: ownerId ?? this.ownerId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
