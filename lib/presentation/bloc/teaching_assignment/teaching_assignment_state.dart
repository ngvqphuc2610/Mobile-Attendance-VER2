import 'package:equatable/equatable.dart';

abstract class TeachingAssignmentState extends Equatable {
  const TeachingAssignmentState();

  @override
  List<Object?> get props => [];
}

class TeachingAssignmentInitial extends TeachingAssignmentState {}

class TeachingAssignmentLoading extends TeachingAssignmentState {}

class TeachingAssignmentsLoaded extends TeachingAssignmentState {
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> filteredAssignments;

  const TeachingAssignmentsLoaded({
    required this.assignments,
    required this.filteredAssignments,
  });

  TeachingAssignmentsLoaded copyWith({
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? filteredAssignments,
  }) {
    return TeachingAssignmentsLoaded(
      assignments: assignments ?? this.assignments,
      filteredAssignments: filteredAssignments ?? this.filteredAssignments,
    );
  }

  @override
  List<Object> get props => [assignments, filteredAssignments];
}

class TeachingAssignmentError extends TeachingAssignmentState {
  final String message;

  const TeachingAssignmentError(this.message);

  @override
  List<Object> get props => [message];
}

class TeachingAssignmentOperationSuccess extends TeachingAssignmentState {
  final String message;

  const TeachingAssignmentOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
