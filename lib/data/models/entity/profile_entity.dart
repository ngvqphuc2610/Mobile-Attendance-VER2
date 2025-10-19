import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String code;
  final String fullName;
  final String? classId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final String? phone;

  const ProfileEntity({
    required this.id,
    required this.code,
    required this.fullName,
    this.classId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.phone,
  });

  factory ProfileEntity.fromJson(Map<String, dynamic> json) {
    return ProfileEntity(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      classId: json['class_id']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'full_name': fullName,
      'class_id': classId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'email': email,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        fullName,
        classId,
        isActive,
        createdAt,
        updatedAt,
        email,
        phone,
      ];
}