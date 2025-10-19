import 'package:equatable/equatable.dart';

abstract class FacultyEvent extends Equatable {
  const FacultyEvent();

  @override
  List<Object?> get props => [];
}

class LoadFaculties extends FacultyEvent {
  const LoadFaculties();
}

class CreateFaculty extends FacultyEvent {
  final String code;
  final String name;

  const CreateFaculty(this.code, this.name);

  @override
  List<Object> get props => [code, name];
}

class UpdateFaculty extends FacultyEvent {
  final String id;
  final String code;
  final String name;

  const UpdateFaculty(this.id, this.code, this.name);

  @override
  List<Object> get props => [id, code, name];
}

class DeleteFaculty extends FacultyEvent {
  final String id;

  const DeleteFaculty(this.id);

  @override
  List<Object> get props => [id];
}

class FilterFaculties extends FacultyEvent {
  final String query;

  const FilterFaculties(this.query);

  @override
  List<Object> get props => [query];
}