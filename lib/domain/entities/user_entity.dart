 import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? code;
  final String role;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final bool phoneVerified;
  final bool totpEnabled;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.code,
    required this.role,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.phoneVerified = false,
    this.totpEnabled = false,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? code,
    String? role,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    bool? phoneVerified,
    bool? totpEnabled,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      code: code ?? this.code,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      totpEnabled: totpEnabled ?? this.totpEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        code,
        role,
        phone,
        isActive,
        createdAt,
        phoneVerified,
        totpEnabled,
      ];
}