import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String code;
  final String fullName;
  final String? classId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final String? phone;

  const Profile({
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

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      code: json['code'],
      fullName: json['full_name'],
      classId: json['class_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      email: json['email'],
      phone: json['phone'],
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
