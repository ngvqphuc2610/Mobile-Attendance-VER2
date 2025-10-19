import 'package:equatable/equatable.dart';

abstract class SessionInstanceEvent extends Equatable {
  const SessionInstanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessionInstances extends SessionInstanceEvent {
  final String? sectionId;

  const LoadSessionInstances({this.sectionId});

  @override
  List<Object?> get props => [sectionId];
}

class CreateSessionInstance extends SessionInstanceEvent {
  final Map<String, dynamic> payload;

  const CreateSessionInstance(this.payload);

  @override
  List<Object> get props => [payload];
}

class UpdateSessionInstance extends SessionInstanceEvent {
  final String id;
  final Map<String, dynamic> payload;

  const UpdateSessionInstance(this.id, this.payload);

  @override
  List<Object> get props => [id, payload];
}

class DeleteSessionInstance extends SessionInstanceEvent {
  final String id;

  const DeleteSessionInstance(this.id);

  @override
  List<Object> get props => [id];
}

class FilterSessionInstances extends SessionInstanceEvent {
  final String query;

  const FilterSessionInstances(this.query);

  @override
  List<Object> get props => [query];
}