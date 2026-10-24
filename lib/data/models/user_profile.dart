import '../../core/enums/user_role.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String storeId;
  final UserRole role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.storeId,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      storeId: json['store_id'] as String,
      role: UserRole.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'store_id': storeId,
        'role': role.name,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isCrew => role == UserRole.crew;

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? storeId,
    UserRole? role,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      storeId: storeId ?? this.storeId,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
