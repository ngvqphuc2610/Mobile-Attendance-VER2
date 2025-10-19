import 'package:equatable/equatable.dart';
import '../../../data/models/dto/teacher_dto.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeachers extends TeacherEvent {
  final String? facultyId;
  final String? search;

  const LoadTeachers({this.facultyId, this.search});

  @override
  List<Object?> get props => [facultyId, search];
}

class LoadTeacherById extends TeacherEvent {
  final String id;

  const LoadTeacherById(this.id);

  @override
  List<Object> get props => [id];
}

class CreateTeacher extends TeacherEvent {
  final TeacherDto teacherDto;

  const CreateTeacher(this.teacherDto);

  @override
  List<Object> get props => [teacherDto];
}

class UpdateTeacher extends TeacherEvent {
  final String id;
  final TeacherDto teacherDto;

  const UpdateTeacher({required this.id, required this.teacherDto});

  @override
  List<Object> get props => [id, teacherDto];
}

class DeleteTeacher extends TeacherEvent {
  final String id;

  const DeleteTeacher(this.id);

  @override
  List<Object> get props => [id];
}

class FilterTeachers extends TeacherEvent {
  final String query;

  const FilterTeachers(this.query);

  @override
  List<Object> get props => [query];
}