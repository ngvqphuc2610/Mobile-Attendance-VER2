import 'profile_entity.dart';
import 'user_role_entity.dart';

class AccountEntity {
  final String id;
  final String profileId;
  final String email;
  final String? username;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileEntity? profile;
  final UserRoleEntity? userRole;
  

  AccountEntity({
    required this.id,
    required this.profileId,
    required this.email,
    this.username,
    required this.isActive,
    required this.isEmailVerified,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
    this.userRole,
  });

  factory AccountEntity.fromJson(Map<String, dynamic> json) {
    return AccountEntity(
      id: json['id'],
      profileId: json['profile_id'],
      email: json['email'],
      username: json['username'],
      isActive: json['is_active'] == 1,
      isEmailVerified: json['is_email_verified'] == 1,
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profile: json['profile'] != null 
          ? ProfileEntity.fromJson(json['profile'])
          : null,
      userRole: json['user_role'] != null
          ? UserRoleEntity.fromJson(json['user_role'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'email': email,
      'username': username,
      'is_active': isActive ? 1 : 0,
      'is_email_verified': isEmailVerified ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (profile != null) 'profile': profile!.toJson(),
      if (userRole != null) 'user_role': userRole!.toJson(),
    };
  }
}