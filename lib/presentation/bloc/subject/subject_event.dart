import 'package:equatable/equatable.dart';

abstract class SubjectEvent extends Equatable {
  const SubjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubjects extends SubjectEvent {
  const LoadSubjects();
}

class CreateSubject extends SubjectEvent {
  final String code;
  final String name;
  final int? credits;

  const CreateSubject(this.code, this.name, this.credits);

  @override
  List<Object?> get props => [code, name, credits];
}

class UpdateSubject extends SubjectEvent {
  final String id;
  final String code;
  final String name;
  final int? credits;

  const UpdateSubject(this.id, this.code, this.name, this.credits);

  @override
  List<Object?> get props => [id, code, name, credits];
}

class DeleteSubject extends SubjectEvent {
  final String id;

  const DeleteSubject(this.id);

  @override
  List<Object> get props => [id];
}

class FilterSubjects extends SubjectEvent {
  final String query;

  const FilterSubjects(this.query);

  @override
  List<Object> get props => [query];
}