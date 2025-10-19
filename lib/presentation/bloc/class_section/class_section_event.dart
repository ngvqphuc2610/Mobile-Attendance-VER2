
import 'package:equatable/equatable.dart';

abstract class ClassSectionEvent extends Equatable {
  const ClassSectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadClassSections extends ClassSectionEvent {
  final String? classId;

  const LoadClassSections({this.classId});

  @override
  List<Object?> get props => [classId];
}

class CreateClassSection extends ClassSectionEvent {
  final Map<String, dynamic> payload;

  const CreateClassSection(this.payload);

  @override
  List<Object> get props => [payload];
}

class UpdateClassSection extends ClassSectionEvent {
  final String sectionId;
  final Map<String, dynamic> payload;

  const UpdateClassSection(this.sectionId, this.payload);

  @override
  List<Object> get props => [sectionId, payload];
}

class DeleteClassSection extends ClassSectionEvent {
  final String id;

  const DeleteClassSection(this.id);

  @override
  List<Object> get props => [id];
}

class FilterClassSections extends ClassSectionEvent {
  final String query;

  const FilterClassSections(this.query);

  @override
  List<Object> get props => [query];
}
class ClearClassSectionFilter extends ClassSectionEvent {}