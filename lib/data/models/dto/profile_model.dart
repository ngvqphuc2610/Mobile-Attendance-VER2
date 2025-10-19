class ProfileModel {
  final String id;
  final String code;
  final String fullName;
  final String? classId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? email;
  final String? phone;

  ProfileModel({
    required this.id,
    required this.code,
    required this.fullName,
    this.classId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.email,
    this.phone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      fullName: json['full_name'] ?? '',
      classId: json['class_id'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'email': email,
      'phone': phone,
    };
  }
}
