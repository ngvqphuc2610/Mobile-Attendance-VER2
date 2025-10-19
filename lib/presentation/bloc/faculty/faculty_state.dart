import 'package:equatable/equatable.dart';
import '../../../data/models/entity/faculty_entity.dart';

abstract class FacultyState extends Equatable {
  const FacultyState();

  @override
  List<Object?> get props => [];
}

class FacultyInitial extends FacultyState {}

class FacultyLoading extends FacultyState {}

class FacultiesLoaded extends FacultyState {
  final List<FacultyEntity> faculties;
  final List<FacultyEntity> filteredFaculties;

  const FacultiesLoaded({
    required this.faculties,
    required this.filteredFaculties,
  });

  @override
  List<Object> get props => [faculties, filteredFaculties];

  FacultiesLoaded copyWith({
    List<FacultyEntity>? faculties,
    List<FacultyEntity>? filteredFaculties,
  }) {
    return FacultiesLoaded(
      faculties: faculties ?? this.faculties,
      filteredFaculties: filteredFaculties ?? this.filteredFaculties,
    );
  }
}

class FacultyError extends FacultyState {
  final String message;

  const FacultyError(this.message);

  @override
  List<Object> get props => [message];
}

class FacultyOperationSuccess extends FacultyState {
  final String message;

  const FacultyOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}