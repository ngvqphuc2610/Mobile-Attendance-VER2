import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String code;
  final String role;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final bool phoneVerified;
  final bool totpEnabled;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.code,
    required this.role,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.phoneVerified = false,
    this.totpEnabled = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      code: json['code'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      phoneVerified: json['phone_verified'] is bool
          ? json['phone_verified'] as bool
          : (json['phone_verified'] is num
              ? (json['phone_verified'] as num) != 0
              : false),
      totpEnabled: json['totp_enabled'] is bool
          ? json['totp_enabled'] as bool
          : (json['totp_enabled'] is num
              ? (json['totp_enabled'] as num) != 0
              : false),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'code': code,
      'role': role,
      'phone': phone,
      'is_active': isActive,
      'phone_verified': phoneVerified,
      'totp_enabled': totpEnabled,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? code,
    String? role,
    String? phone,
    bool? isActive,
    bool? phoneVerified,
    bool? totpEnabled,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      code: code ?? this.code,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
