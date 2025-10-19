import 'package:equatable/equatable.dart';
import '../../../data/models/entity/subject_entity.dart';

abstract class SubjectState extends Equatable {
  const SubjectState();

  @override
  List<Object?> get props => [];
}

class SubjectInitial extends SubjectState {}

class SubjectLoading extends SubjectState {}

class SubjectsLoaded extends SubjectState {
  final List<SubjectEntity> subjects;
  final List<SubjectEntity> filteredSubjects;

  const SubjectsLoaded({
    required this.subjects,
    required this.filteredSubjects,
  });

  @override
  List<Object> get props => [subjects, filteredSubjects];

  SubjectsLoaded copyWith({
    List<SubjectEntity>? subjects,
    List<SubjectEntity>? filteredSubjects,
  }) {
    return SubjectsLoaded(
      subjects: subjects ?? this.subjects,
      filteredSubjects: filteredSubjects ?? this.filteredSubjects,
    );
  }
}

class SubjectError extends SubjectState {
  final String message;

  const SubjectError(this.message);

  @override
  List<Object> get props => [message];
}

class SubjectOperationSuccess extends SubjectState {
  final String message;

  const SubjectOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}