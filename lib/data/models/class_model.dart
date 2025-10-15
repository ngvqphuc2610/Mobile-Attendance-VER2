class ClassModel {
  final String id;
  final String code;
  final String name;
  final String? facultyId;
  final String? facultyName;
  final String? facultyCode;
  final String? cohortId;
  final int? cohortYear;
  final DateTime? createdAt;

  ClassModel({
    required this.id,
    required this.code,
    required this.name,
    this.facultyId,
    this.facultyName,
    this.facultyCode,
    this.cohortId,
    this.cohortYear,
    this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      facultyId: json['faculty_id'],
      facultyName: json['faculty_name'],
      facultyCode: json['faculty_code'],
      cohortId: json['cohort_id'],
      cohortYear: json['cohort_year'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'faculty_code': facultyCode,
      'cohort_id': cohortId,
      'cohort_year': cohortYear,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
