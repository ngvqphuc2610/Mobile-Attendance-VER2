import 'package:equatable/equatable.dart';

import 'cohort.dart';
import 'faculty_entity.dart';

class ClassEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final DateTime? createdAt;
  final String? facultyId;
  final String? facultyName;
  final String? facultyCode;
  final String? cohortId;
  final int? cohortYear;
  final FacultyEntity? faculty;
  final Cohort? cohort;

  const ClassEntity({
    required this.id,
    required this.code,
    required this.name,
    this.createdAt,
    this.facultyId,
    this.facultyName,
    this.facultyCode,
    this.cohortId,
    this.cohortYear,
    this.faculty,
    this.cohort,
  });

  factory ClassEntity.fromJson(Map<String, dynamic> json) {
    return ClassEntity(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      facultyId: json['faculty_id']?.toString(),
      facultyName: json['faculty_name']?.toString(),
      facultyCode: json['faculty_code']?.toString(),
      cohortId: json['cohort_id']?.toString(),
      cohortYear: json['cohort_year'] is num
          ? (json['cohort_year'] as num).toInt()
          : int.tryParse(json['cohort_year']?.toString() ?? ''),
      faculty: json['faculty'] != null
          ? FacultyEntity.fromJson(json['faculty'])
          : null,
      cohort: json['cohort'] != null ? Cohort.fromJson(json['cohort']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'faculty_code': facultyCode,
      'cohort_id': cohortId,
      'cohort_year': cohortYear,
      'faculty': faculty?.toJson(),
      'cohort': cohort?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        createdAt,
        facultyId,
        facultyName,
        facultyCode,
        cohortId,
        cohortYear,
        faculty,
        cohort,
      ];
}
