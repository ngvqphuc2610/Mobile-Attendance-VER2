
import 'package:equatable/equatable.dart';

class UserRoleEntity extends Equatable {
  final String userId;
  final String role;
  final DateTime createdAt;

  const UserRoleEntity({
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  factory UserRoleEntity.fromJson(Map<String, dynamic> json) {
    return UserRoleEntity(
      userId: json['user_id'] ?? '',
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, role, createdAt];
}