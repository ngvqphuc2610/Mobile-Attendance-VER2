import 'package:equatable/equatable.dart';

enum UserRoleType { student, teacher, admin }

class UserRole extends Equatable {
  final String userId;
  final UserRoleType role;
  final DateTime createdAt;

  const UserRole({
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      userId: json['user_id'] ?? '',
      role: _parseRole(json['role']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static UserRoleType _parseRole(dynamic value) {
    final roleValue = (value ?? '').toString().toLowerCase();
    switch (roleValue) {
      case 'teacher':
        return UserRoleType.teacher;
      case 'admin':
        return UserRoleType.admin;
      case 'student':
      default:
        return UserRoleType.student;
    }
  }

  @override
  List<Object?> get props => [userId, role, createdAt];
}
