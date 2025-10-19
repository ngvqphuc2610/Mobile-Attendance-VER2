
import 'package:equatable/equatable.dart';
import '../../../data/models/entity/class_section_entity.dart';

abstract class ClassSectionState extends Equatable {
  const ClassSectionState();

  @override
  List<Object?> get props => [];
}

class ClassSectionInitial extends ClassSectionState {}

class ClassSectionLoading extends ClassSectionState {}

class ClassSectionsLoaded extends ClassSectionState {
  final List<ClassSectionEntity> sections;
  final List<ClassSectionEntity> filteredSections;

  const ClassSectionsLoaded({
    required this.sections,
    required this.filteredSections,
  });

  ClassSectionsLoaded copyWith({
    List<ClassSectionEntity>? sections,
    List<ClassSectionEntity>? filteredSections,
  }) {
    return ClassSectionsLoaded(
      sections: sections ?? this.sections,
      filteredSections: filteredSections ?? this.filteredSections,
    );
  }

  @override
  List<Object> get props => [sections, filteredSections];
}

class ClassSectionError extends ClassSectionState {
  final String message;

  const ClassSectionError(this.message);

  @override
  List<Object> get props => [message];
}

class ClassSectionOperationSuccess extends ClassSectionState {
  final String message;

  const ClassSectionOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}