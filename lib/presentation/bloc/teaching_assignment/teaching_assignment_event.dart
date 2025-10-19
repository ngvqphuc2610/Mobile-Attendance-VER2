import 'package:equatable/equatable.dart';

abstract class TeachingAssignmentEvent extends Equatable {
  const TeachingAssignmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeachingAssignments extends TeachingAssignmentEvent {
  const LoadTeachingAssignments();
}

class CreateTeachingAssignment extends TeachingAssignmentEvent {
  final Map<String, dynamic> payload;

  const CreateTeachingAssignment(this.payload);

  @override
  List<Object> get props => [payload];
}

class UpdateTeachingAssignment extends TeachingAssignmentEvent {
  final String id;
  final Map<String, dynamic> payload;

  const UpdateTeachingAssignment(this.id, this.payload);

  @override
  List<Object> get props => [id, payload];
}

class DeleteTeachingAssignment extends TeachingAssignmentEvent {
  final String id;

  const DeleteTeachingAssignment(this.id);

  @override
  List<Object> get props => [id];
}

class FilterTeachingAssignments extends TeachingAssignmentEvent {
  final String query;

  const FilterTeachingAssignments(this.query);

  @override
  List<Object> get props => [query];
}
