import 'package:equatable/equatable.dart';

abstract class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentsEvent extends StudentEvent {
  const LoadStudentsEvent();
}

class LoadStudentByIdEvent extends StudentEvent {
  final String id;

  const LoadStudentByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchStudentsEvent extends StudentEvent {
  final String query;

  const SearchStudentsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateStudentEvent extends StudentEvent {
  final String code;
  final String fullName;
  final String? classId;

  const CreateStudentEvent({
    required this.code,
    required this.fullName,
    this.classId,
  });

  @override
  List<Object?> get props => [code, fullName, classId];
}

class UpdateStudentEvent extends StudentEvent {
  final String id;
  final String code;
  final String fullName;
  final String? classId;
  final bool isActive;

  const UpdateStudentEvent({
    required this.id,
    required this.code,
    required this.fullName,
    this.classId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, code, fullName, classId, isActive];
}

class DeleteStudentEvent extends StudentEvent {
  final String id;

  const DeleteStudentEvent(this.id);

  @override
  List<Object?> get props => [id];
}
