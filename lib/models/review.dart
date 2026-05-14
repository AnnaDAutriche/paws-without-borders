class Review {
  final String id;
  final String shelterId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.shelterId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  /// NOTE: We intentionally do NOT persist `id` into Firestore documents.
  /// The Firestore document ID (`doc.id`) is the single source of truth.
  Map<String, dynamic> toJson() => {
        'shelter_id': shelterId,
        'user_id': userId,
        'user_name': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// `id` must be provided by the caller (e.g. Firestore `doc.id`).
  /// Never read `json['id']`.
  factory Review.fromJson({required String id, required Map<String, dynamic> json}) => Review(
        id: id,
        shelterId: (json['shelter_id'] ?? json['shelterId']) as String,
        userId: (json['user_id'] ?? json['userId']) as String,
        userName: (json['user_name'] ?? json['userName']) as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Review copyWith({
    String? id,
    String? shelterId,
    String? userId,
    String? userName,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Review(
    id: id ?? this.id,
    shelterId: shelterId ?? this.shelterId,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get initials {
    final parts = userName.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
