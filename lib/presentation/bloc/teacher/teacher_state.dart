import 'package:equatable/equatable.dart';
import '../../../data/models/entity/teacher_entity.dart';

abstract class TeacherState extends Equatable {
  const TeacherState();

  @override
  List<Object?> get props => [];
}

class TeacherInitial extends TeacherState {}

class TeacherLoading extends TeacherState {}

class TeachersLoaded extends TeacherState {
  final List<TeacherEntity> teachers;
  final List<TeacherEntity> filteredTeachers;

  const TeachersLoaded({
    required this.teachers,
    required this.filteredTeachers,
  });

  @override
  List<Object> get props => [teachers, filteredTeachers];

  TeachersLoaded copyWith({
    List<TeacherEntity>? teachers,
    List<TeacherEntity>? filteredTeachers,
  }) {
    return TeachersLoaded(
      teachers: teachers ?? this.teachers,
      filteredTeachers: filteredTeachers ?? this.filteredTeachers,
    );
  }
}

class TeacherLoaded extends TeacherState {
  final TeacherEntity teacher;

  const TeacherLoaded(this.teacher);

  @override
  List<Object> get props => [teacher];
}

class TeacherError extends TeacherState {
  final String message;

  const TeacherError(this.message);

  @override
  List<Object> get props => [message];
}

class TeacherOperationSuccess extends TeacherState {
  final String message;

  const TeacherOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}