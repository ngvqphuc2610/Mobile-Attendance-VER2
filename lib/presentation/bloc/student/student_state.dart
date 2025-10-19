import 'package:equatable/equatable.dart';
import '../../../data/models/entity/student_entity.dart';

abstract class StudentState extends Equatable {
  const StudentState();

  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {}

class StudentLoading extends StudentState {}

class StudentsLoaded extends StudentState {
  final List<StudentEntity> students;
  final List<StudentEntity> filteredStudents;

  const StudentsLoaded({
    required this.students,
    required this.filteredStudents,
  });

  @override
  List<Object> get props => [students, filteredStudents];

  StudentsLoaded copyWith({
    List<StudentEntity>? students,
    List<StudentEntity>? filteredStudents,
  }) {
    return StudentsLoaded(
      students: students ?? this.students,
      filteredStudents: filteredStudents ?? this.filteredStudents,
    );
  }
}

class StudentLoaded extends StudentState {
  final StudentEntity student;

  const StudentLoaded(this.student);

  @override
  List<Object> get props => [student];
}

class StudentError extends StudentState {
  final String message;

  const StudentError(this.message);

  @override
  List<Object> get props => [message];
}

class StudentOperationSuccess extends StudentState {
  final String message;

  const StudentOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
