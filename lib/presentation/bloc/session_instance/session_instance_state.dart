import 'package:equatable/equatable.dart';

abstract class SessionInstanceState extends Equatable {
  const SessionInstanceState();

  @override
  List<Object?> get props => [];
}

class SessionInstanceInitial extends SessionInstanceState {}

class SessionInstanceLoading extends SessionInstanceState {}

class SessionInstancesLoaded extends SessionInstanceState {
  final List<Map<String, dynamic>> instances;
  final List<Map<String, dynamic>> filteredInstances;

  const SessionInstancesLoaded({
    required this.instances,
    required this.filteredInstances,
  });

  SessionInstancesLoaded copyWith({
    List<Map<String, dynamic>>? instances,
    List<Map<String, dynamic>>? filteredInstances,
  }) {
    return SessionInstancesLoaded(
      instances: instances ?? this.instances,
      filteredInstances: filteredInstances ?? this.filteredInstances,
    );
  }

  @override
  List<Object> get props => [instances, filteredInstances];
}

class SessionInstanceError extends SessionInstanceState {
  final String message;

  const SessionInstanceError(this.message);

  @override
  List<Object> get props => [message];
}

class SessionInstanceOperationSuccess extends SessionInstanceState {
  final String message;

  const SessionInstanceOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}