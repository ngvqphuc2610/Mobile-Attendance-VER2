import 'package:equatable/equatable.dart';

import '../../../data/models/entity/class_entity.dart';

abstract class ClassState extends Equatable {
  const ClassState();

  @override
  List<Object?> get props => [];
}

class ClassInitial extends ClassState {}

class ClassLoading extends ClassState {}

class ClassesLoaded extends ClassState {
  final List<ClassEntity> classes;
  final List<ClassEntity> filteredClasses;

  const ClassesLoaded({
    required this.classes,
    required this.filteredClasses,
  });

  ClassesLoaded copyWith({
    List<ClassEntity>? classes,
    List<ClassEntity>? filteredClasses,
  }) {
    return ClassesLoaded(
      classes: classes ?? this.classes,
      filteredClasses: filteredClasses ?? this.filteredClasses,
    );
  }

  @override
  List<Object> get props => [classes, filteredClasses];
}

class ClassError extends ClassState {
  final String message;

  const ClassError(this.message);

  @override
  List<Object> get props => [message];
}

class ClassOperationSuccess extends ClassState {
  final String message;

  const ClassOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
