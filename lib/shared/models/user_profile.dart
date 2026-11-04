/// Represents the authenticated user's profile in Yaadibook.
class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String preferredLanguage;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.preferredLanguage = 'en',
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      preferredLanguage: (json['preferred_language'] as String?) ?? 'en',
      avatarPath: json['avatar_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'preferred_language': preferredLanguage,
      'avatar_path': avatarPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
