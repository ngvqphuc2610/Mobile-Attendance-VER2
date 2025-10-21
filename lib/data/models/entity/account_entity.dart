import 'profile_entity.dart';
import 'user_role_entity.dart';

DateTime? _dtTryParse(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

bool _boolFrom01OrBool(dynamic v, {bool fallback = true}) {
  if (v is bool) return v;
  if (v == null) return fallback;
  final s = v.toString();
  return s == '1' || s.toLowerCase() == 'true';
}

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
    ProfileEntity? profile;
    if (json['profile'] is Map) {
      profile = ProfileEntity.fromJson(
        Map<String, dynamic>.from(json['profile']),
      );
    } else if (json.containsKey('profile_id') ||
        json.containsKey('full_name') ||
        json.containsKey('code')) {
      profile = ProfileEntity(
        id: json['profile_id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        classId: json['class_id']?.toString(),
        isActive: _boolFrom01OrBool(json['profile_is_active'] ?? json['is_active'],
            fallback: true),
        createdAt: _dtTryParse(
              json['profile_created_at'] ?? json['created_at'],
            ) ??
            DateTime.now(),
        updatedAt: _dtTryParse(
              json['profile_updated_at'] ?? json['updated_at'],
            ) ??
            DateTime.now(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
      );
    }

    UserRoleEntity? userRole;
    if (json['user_role'] is Map) {
      userRole = UserRoleEntity.fromJson(
        Map<String, dynamic>.from(json['user_role']),
      );
    } else if (json['role'] != null) {
      userRole = UserRoleEntity(
        userId: json['profile_id']?.toString() ?? json['id']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        createdAt:
            _dtTryParse(json['role_created_at']) ?? DateTime.now(),
      );
    }

    return AccountEntity(
      id: (json['id'] ?? '').toString(),                     
      profileId: (json['profile_id'] ?? '').toString(),      
      email: (json['email'] ?? '').toString(),               
      username: (json['username'] as String?),               
      isActive: _boolFrom01OrBool(json['is_active'], fallback: true),
      isEmailVerified: _boolFrom01OrBool(json['is_email_verified'], fallback: false),
      lastLoginAt: _dtTryParse(json['last_login_at']),
      createdAt: _dtTryParse(json['created_at']) ?? DateTime.now(),   
      updatedAt: _dtTryParse(json['updated_at']) ?? DateTime.now(),   
      profile: profile,                                                    
      userRole: userRole,                                                    
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
