import 'package:equatable/equatable.dart';
import '../../../data/models/dto/student_dto.dart';

abstract class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudents extends StudentEvent {
  final String? classId;
  final String? search;
  final int? page;
  final int? limit;

  const LoadStudents({
    this.classId,
    this.search,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [classId, search, page, limit];
}

class LoadStudentById extends StudentEvent {
  final String id;

  const LoadStudentById(this.id);

  @override
  List<Object> get props => [id];
}

class CreateStudent extends StudentEvent {
  final StudentDto studentDto;

  const CreateStudent(this.studentDto);

  @override
  List<Object> get props => [studentDto];
}

class UpdateStudent extends StudentEvent {
  final String id;
  final StudentDto studentDto;

  const UpdateStudent({
    required this.id,
    required this.studentDto,
  });

  @override
  List<Object> get props => [id, studentDto];
}

class DeleteStudent extends StudentEvent {
  final String id;

  const DeleteStudent(this.id);

  @override
  List<Object> get props => [id];
}

class FilterStudents extends StudentEvent {
  final String query;

  const FilterStudents(this.query);

  @override
  List<Object> get props => [query];
}
