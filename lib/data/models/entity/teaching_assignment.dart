import 'package:equatable/equatable.dart';

class TeachingAssignment extends Equatable {
  final String sectionId;
  final String teacherId;
  final String role;

  const TeachingAssignment({
    required this.sectionId,
    required this.teacherId,
    required this.role,
  });

  factory TeachingAssignment.fromJson(Map<String, dynamic> json) {
    return TeachingAssignment(
      sectionId: json['section_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      role: json['role'] ?? 'lecturer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'teacher_id': teacherId,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [sectionId, teacherId, role];
}
