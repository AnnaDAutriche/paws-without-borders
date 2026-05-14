class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  /// NOTE: We intentionally do NOT persist `id` into Firestore documents.
  /// The Firestore document ID (`doc.id`) is the single source of truth.
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// `id` must be provided by the caller (e.g. Firestore `doc.id`).
  /// Never read `json['id']`.
  factory User.fromJson({required String id, required Map<String, dynamic> json}) => User(
        id: id,
        name: json['name'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
