class TeacherModel {
  final String profileId;
  final String code;
  final String fullName;
  final String email;
  final String? phone;
  final String? facultyId;
  final String? facultyName;
  final String? facultyCode;
  final String? title;
  final String? office;
  final bool isActive;
  final DateTime? createdAt;

  TeacherModel({
    required this.profileId,
    required this.code,
    required this.fullName,
    required this.email,
    this.phone,
    this.facultyId,
    this.facultyName,
    this.facultyCode,
    this.title,
    this.office,
    this.isActive = true,
    this.createdAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      profileId: json['profile_id'] ?? '',
      code: json['code'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      facultyId: json['faculty_id'],
      facultyName: json['faculty_name'],
      facultyCode: json['faculty_code'],
      title: json['title'],
      office: json['office'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'code': code,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'faculty_code': facultyCode,
      'title': title,
      'office': office,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}