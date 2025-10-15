class StudentModel {
  final String profileId;
  final String code;
  final String fullName;
  final String email;
  final String? phone;
  final String? classId;
  final String? className;
  final String? classCode;
  final String? facultyName;
  final String? facultyCode;
  final String? mssv;
  final int? mssvCohort;
  final String? mssvTrackCode;
  final int? mssvSerial;
  final bool isActive;
  final DateTime? createdAt;

  StudentModel({
    required this.profileId,
    required this.code,
    required this.fullName,
    required this.email,
    this.phone,
    this.classId,
    this.className,
    this.classCode,
    this.facultyName,
    this.facultyCode,
    this.mssv,
    this.mssvCohort,
    this.mssvTrackCode,
    this.mssvSerial,
    this.isActive = true,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      profileId: json['profile_id'] ?? '',
      code: json['code'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      classId: json['class_id'],
      className: json['class_name'],
      classCode: json['class_code'],
      facultyName: json['faculty_name'],
      facultyCode: json['faculty_code'],
      mssv: json['mssv'],
      mssvCohort: json['mssv_cohort'],
      mssvTrackCode: json['mssv_track_code'],
      mssvSerial: json['mssv_serial'],
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
      'class_id': classId,
      'class_name': className,
      'class_code': classCode,
      'faculty_name': facultyName,
      'faculty_code': facultyCode,
      'mssv': mssv,
      'mssv_cohort': mssvCohort,
      'mssv_track_code': mssvTrackCode,
      'mssv_serial': mssvSerial,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}