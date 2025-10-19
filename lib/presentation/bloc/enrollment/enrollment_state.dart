
import 'package:equatable/equatable.dart';
import '../../../data/models/entity/enrollment_entity.dart';

abstract class EnrollmentState extends Equatable {
  const EnrollmentState();

  @override
  List<Object?> get props => [];
}

class EnrollmentInitial extends EnrollmentState {}

class EnrollmentLoading extends EnrollmentState {}

class EnrollmentsLoaded extends EnrollmentState {
  final List<EnrollmentEntity> enrollments;
  final List<EnrollmentEntity> filteredEnrollments;

  const EnrollmentsLoaded({
    required this.enrollments,
    required this.filteredEnrollments,
  });

  @override
  List<Object> get props => [enrollments, filteredEnrollments];

  EnrollmentsLoaded copyWith({
    List<EnrollmentEntity>? enrollments,
    List<EnrollmentEntity>? filteredEnrollments,
  }) {
    return EnrollmentsLoaded(
      enrollments: enrollments ?? this.enrollments,
      filteredEnrollments: filteredEnrollments ?? this.filteredEnrollments,
    );
  }
}

class EnrollmentOperationSuccess extends EnrollmentState {
  final String message;

  const EnrollmentOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class EnrollmentError extends EnrollmentState {
  final String message;

  const EnrollmentError(this.message);

  @override
  List<Object> get props => [message];
}
