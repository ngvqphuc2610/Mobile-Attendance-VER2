
import 'package:equatable/equatable.dart';

class ClassSectionEntity extends Equatable {
  final String id;
  final String subjectId;
  final int semester;
  final int year;
  final String sectionCode;
  final int? capacity;
  final ClassSectionSubject? subject;

  const ClassSectionEntity({
    required this.id,
    required this.subjectId,
    required this.semester,
    required this.year,
    required this.sectionCode,
    this.capacity,
    this.subject,
  });

  factory ClassSectionEntity.fromJson(Map<String, dynamic> json) {
    return ClassSectionEntity(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      semester: _toInt(json['semester']),
      year: _toInt(json['year']),
      sectionCode: json['section_code']?.toString() ?? '',
      capacity: json['capacity'] != null ? (json['capacity'] as num).toInt() : null,
      subject: _parseSubject(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'semester': semester,
      'year': year,
      'section_code': sectionCode,
      'capacity': capacity,
      if (subject != null) 'subject': subject!.toJson(),
    };
  }

  static ClassSectionSubject? _parseSubject(Map<String, dynamic> json) {
    final raw = json['subject'];
    if (raw is Map<String, dynamic>) {
      return ClassSectionSubject.fromJson(raw);
    }

    if (json.containsKey('subject_name') ||
        json.containsKey('subject_code') ||
        json.containsKey('subject_id')) {
      return ClassSectionSubject(
        id: json['subject_id']?.toString(),
        code: json['subject_code']?.toString(),
        name: json['subject_name']?.toString(),
        credits: json['subject_credits'] != null
            ? (json['subject_credits'] as num?)?.toInt()
            : null,
      );
    }
    return null;
  }

  static int _toInt(dynamic value) => value != null ? (value as num).toInt() : 0;

  @override
  List<Object?> get props => [
        id,
        subjectId,
        semester,
        year,
        sectionCode,
        capacity,
        subject,
      ];
}

class ClassSectionSubject extends Equatable {
  final String? id;
  final String? code;
  final String? name;
  final int? credits;

  const ClassSectionSubject({
    this.id,
    this.code,
    this.name,
    this.credits,
  });

  factory ClassSectionSubject.fromJson(Map<String, dynamic> json) {
    return ClassSectionSubject(
      id: json['id']?.toString() ?? json['subject_id']?.toString(),
      code: json['code']?.toString() ?? json['subject_code']?.toString(),
      name: json['name']?.toString() ?? json['subject_name']?.toString(),
      credits: json['credits'] != null
          ? (json['credits'] as num?)?.toInt()
          : (json['subject_credits'] as num?)?.toInt(),
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
      
