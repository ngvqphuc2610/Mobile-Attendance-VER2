import 'package:equatable/equatable.dart';

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

class EnrollmentEntity extends Equatable {
  final String id;
  final String sectionId;
  final String studentId;
  final EnrollmentStudent? student;
  final EnrollmentSection? section;

  const EnrollmentEntity({
    required this.id,
    required this.sectionId,
    required this.studentId,
    this.student,
    this.section,
  });

  factory EnrollmentEntity.fromJson(Map<String, dynamic> json) {
    final compositeId = json['id']?.toString();
    final sectionId = json['section_id']?.toString() ?? '';
    final studentId = json['student_id']?.toString() ?? '';

    return EnrollmentEntity(
      id: compositeId ?? '$sectionId:$studentId',
      sectionId: sectionId,
      studentId: studentId,
      student: _parseStudent(json),
      section: _parseSection(json, sectionId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'student_id': studentId,
      if (student != null) 'student': student!.toJson(),
      if (section != null) 'section': section!.toJson(),
    };
  }

  static EnrollmentStudent? _parseStudent(Map<String, dynamic> json) {
    final rawStudent = json['student'];

    if (rawStudent is Map<String, dynamic>) {
      return EnrollmentStudent.fromJson(rawStudent);
    }

    if (json.containsKey('student_name') ||
        json.containsKey('student_code') ||
        json.containsKey('student_id')) {
      return EnrollmentStudent(
        id: json['student_id']?.toString() ?? '',
        code: json['student_code']?.toString(),
        fullName: json['student_name']?.toString(),
      );
    }

    return null;
  }

  static EnrollmentSection? _parseSection(
    Map<String, dynamic> json,
    String fallbackSectionId,
  ) {
    final rawSection = json['section'];

    if (rawSection is Map<String, dynamic>) {
      return EnrollmentSection.fromJson(rawSection);
    }

    if (json.containsKey('section_code') ||
        json.containsKey('semester') ||
        json.containsKey('year') ||
        json.containsKey('subject_id')) {
      return EnrollmentSection(
        id: fallbackSectionId,
        sectionCode: json['section_code']?.toString(),
        semester: _nullableInt(json['semester']),
        year: _nullableInt(json['year']),
        subject: EnrollmentSubject(
          id: json['subject_id']?.toString(),
          code: json['subject_code']?.toString(),
          name: json['subject_name']?.toString(),
        ),
      );
    }

    return null;
  }
  @override
  List<Object?> get props => [
        id,
        sectionId,
        studentId,
        student,
        section,
      ];
}

class EnrollmentStudent extends Equatable {
  final String id;
  final String? code;
  final String? fullName;

  const EnrollmentStudent({
    required this.id,
    this.code,
    this.fullName,
  });

  factory EnrollmentStudent.fromJson(Map<String, dynamic> json) {
    return EnrollmentStudent(
      id: json['id']?.toString() ??
          json['student_id']?.toString() ??
          '',
      code: json['code']?.toString() ?? json['student_code']?.toString(),
      fullName: json['full_name']?.toString() ??
          json['name']?.toString() ??
          json['student_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'full_name': fullName,
    };
  }

  @override
  List<Object?> get props => [id, code, fullName];
}

class EnrollmentSection extends Equatable {
  final String id;
  final String? sectionCode;
  final int? semester;
  final int? year;
  final EnrollmentSubject? subject;

  const EnrollmentSection({
    required this.id,
    this.sectionCode,
    this.semester,
    this.year,
    this.subject,
  });

  factory EnrollmentSection.fromJson(Map<String, dynamic> json) {
    return EnrollmentSection(
      id: json['id']?.toString() ??
          json['section_id']?.toString() ??
          '',
      sectionCode: json['section_code']?.toString(),
      semester: _nullableInt(json['semester']),
      year: _nullableInt(json['year']),
      subject: json['subject'] is Map<String, dynamic>
          ? EnrollmentSubject.fromJson(json['subject'])
          : EnrollmentSubject(
              id: json['subject_id']?.toString(),
              code: json['subject_code']?.toString(),
              name: json['subject_name']?.toString(),
              credits: _nullableInt(json['subject_credits']),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_code': sectionCode,
      'semester': semester,
      'year': year,
      if (subject != null) 'subject': subject!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        sectionCode,
        semester,
        year,
        subject,
      ];
}

class EnrollmentSubject extends Equatable {
  final String? id;
  final String? code;
  final String? name;
  final int? credits;

  const EnrollmentSubject({
    this.id,
    this.code,
    this.name,
    this.credits,
  });

  factory EnrollmentSubject.fromJson(Map<String, dynamic> json) {
    return EnrollmentSubject(
      id: json['id']?.toString() ??
          json['subject_id']?.toString(),
      code: json['code']?.toString() ??
          json['subject_code']?.toString(),
      name: json['name']?.toString() ??
          json['subject_name']?.toString(),
      credits: _nullableInt(json['credits'] ?? json['subject_credits']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'credits': credits,
    };
  }

  @override
  List<Object?> get props => [id, code, name, credits];
}
