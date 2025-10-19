import 'package:equatable/equatable.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class LoadRooms extends RoomEvent {
  const LoadRooms();
}

class CreateRoom extends RoomEvent {
  final String code;
  final String name;
  final int? capacity;
  final String? location;

  const CreateRoom(this.code, this.name, this.capacity, this.location);

  @override
  List<Object?> get props => [code, name, capacity, location];
}

class UpdateRoom extends RoomEvent {
  final String id;
  final String code;
  final String name;
  final int? capacity;
  final String? location;

  const UpdateRoom(this.id, this.code, this.name, this.capacity, this.location);

  @override
  List<Object?> get props => [id, code, name, capacity, location];
}

class DeleteRoom extends RoomEvent {
  final String id;

  const DeleteRoom(this.id);

  @override
  List<Object> get props => [id];
}

class FilterRooms extends RoomEvent {
  final String query;

  const FilterRooms(this.query);

  @override
  List<Object> get props => [query];
}