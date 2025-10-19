import 'package:equatable/equatable.dart';
import '../../../data/models/entity/room_entity.dart';

abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomsLoaded extends RoomState {
  final List<RoomEntity> rooms;
  final List<RoomEntity> filteredRooms;

  const RoomsLoaded({
    required this.rooms,
    required this.filteredRooms,
  });

  @override
  List<Object> get props => [rooms, filteredRooms];

  RoomsLoaded copyWith({
    List<RoomEntity>? rooms,
    List<RoomEntity>? filteredRooms,
  }) {
    return RoomsLoaded(
      rooms: rooms ?? this.rooms,
      filteredRooms: filteredRooms ?? this.filteredRooms,
    );
  }
}

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  @override
  List<Object> get props => [message];
}

class RoomOperationSuccess extends RoomState {
  final String message;

  const RoomOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}