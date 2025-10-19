import 'package:equatable/equatable.dart';

abstract class ClassEvent extends Equatable {
  const ClassEvent();

  @override
  List<Object?> get props => [];
}

class LoadClasses extends ClassEvent {
  final String? facultyId;
  final String? search;

  const LoadClasses({this.facultyId, this.search});

  @override
  List<Object?> get props => [facultyId, search];
}

class CreateClass extends ClassEvent {
  final String code;
  final String name;
  final String? facultyId;
  final String? cohortId;

  const CreateClass({
    required this.code,
    required this.name,
    this.facultyId,
    this.cohortId,
  });

  @override
  List<Object?> get props => [code, name, facultyId, cohortId];
}

class UpdateClass extends ClassEvent {
  final String id;
  final String code;
  final String name;
  final String? facultyId;
  final String? cohortId;

  const UpdateClass({
    required this.id,
    required this.code,
    required this.name,
    this.facultyId,
    this.cohortId,
  });

  @override
  List<Object?> get props => [id, code, name, facultyId, cohortId];
}

class DeleteClass extends ClassEvent {
  final String id;

  const DeleteClass(this.id);

  @override
  List<Object> get props => [id];
}

class FilterClasses extends ClassEvent {
  final String query;

  const FilterClasses(this.query);

  @override
  List<Object> get props => [query];
}
