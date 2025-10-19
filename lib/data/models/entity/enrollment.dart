import 'package:equatable/equatable.dart';

class Enrollment extends Equatable {
  final String sectionId;
  final String studentId;

  const Enrollment({
    required this.sectionId,
    required this.studentId,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      sectionId: json['section_id'] ?? '',
      studentId: json['student_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'student_id': studentId,
    };
  }

  @override
  List<Object?> get props => [sectionId, studentId];
}
