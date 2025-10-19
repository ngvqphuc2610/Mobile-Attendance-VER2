import 'package:equatable/equatable.dart';

class TeachingAssignmentModel extends Equatable {
  final String sectionId;
  final String teacherId;
  final String role;
  final String? sectionCode;
  final String? teacherName;
  final String? teacherCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeachingAssignmentModel({
    required this.sectionId,
    required this.teacherId,
    required this.role,
    this.sectionCode,
    this.teacherName,
    this.teacherCode,
    this.createdAt,
    this.updatedAt,
  });

  factory TeachingAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeachingAssignmentModel(
      sectionId: json['section_id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'lecturer',
      sectionCode: json['section_code']?.toString(),
      teacherName: json['teacher_name']?.toString(),
      teacherCode: json['teacher_code']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'teacher_id': teacherId,
      'role': role,
      'section_code': sectionCode,
      'teacher_name': teacherName,
      'teacher_code': teacherCode,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TeachingAssignmentModel copyWith({
    String? sectionId,
    String? teacherId,
    String? role,
    String? sectionCode,
    String? teacherName,
    String? teacherCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeachingAssignmentModel(
      sectionId: sectionId ?? this.sectionId,
      teacherId: teacherId ?? this.teacherId,
      role: role ?? this.role,
      sectionCode: sectionCode ?? this.sectionCode,
      teacherName: teacherName ?? this.teacherName,
      teacherCode: teacherCode ?? this.teacherCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        sectionId,
        teacherId,
        role,
        sectionCode,
        teacherName,
        teacherCode,
        createdAt,
        updatedAt,
      ];
}