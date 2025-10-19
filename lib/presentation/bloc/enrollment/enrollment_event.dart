import 'package:equatable/equatable.dart';

abstract class EnrollmentEvent extends Equatable {
  const EnrollmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadEnrollments extends EnrollmentEvent {
  final String? sectionId;
  final String? studentId;

  const LoadEnrollments({
    this.sectionId,
    this.studentId,
  });

  @override
  List<Object?> get props => [sectionId, studentId];
}

class CreateEnrollment extends EnrollmentEvent {
  final String enrollmentId;
  final String sectionId;
  final String studentId;

  const CreateEnrollment({
    required this.enrollmentId,
    required this.sectionId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [enrollmentId, sectionId, studentId];
}

class DeleteEnrollment extends EnrollmentEvent {
  final String enrollmentId;
  final String sectionId;
  final String studentId;

  const DeleteEnrollment( this.enrollmentId, this.sectionId, this.studentId);

  @override
  List<Object?> get props => [enrollmentId, sectionId, studentId];
}

class FilterEnrollments extends EnrollmentEvent {
  final String query;

  const FilterEnrollments(this.query);

  @override
  List<Object?> get props => [query];
}
