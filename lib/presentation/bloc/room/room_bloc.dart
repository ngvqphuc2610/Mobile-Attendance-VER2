import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/room_repository.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final RoomRepository _repository;

  RoomBloc({required RoomRepository repository})
      : _repository = repository,
        super(RoomInitial()) {
    on<LoadRooms>(_onLoadRooms);
    on<CreateRoom>(_onCreateRoom);
    on<UpdateRoom>(_onUpdateRoom);
    on<DeleteRoom>(_onDeleteRoom);
    on<FilterRooms>(_onFilterRooms);
  }

  Future<void> _onLoadRooms(
    LoadRooms event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    try {
      final rooms = await _repository.getRooms();
      emit(RoomsLoaded(
        rooms: rooms,
        filteredRooms: rooms,
      ));
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onCreateRoom(
    CreateRoom event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.createRoom(
        code: event.code,
        name: event.name,
        capacity: event.capacity,
        location: event.location,
      );
      emit(const RoomOperationSuccess('Thêm phòng học thành công'));
      add(const LoadRooms());
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onUpdateRoom(
    UpdateRoom event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.updateRoom(
        id: event.id,
        code: event.code,
        name: event.name,
        capacity: event.capacity,
        location: event.location,
      );
      emit(const RoomOperationSuccess('Cập nhật phòng học thành công'));
      add(const LoadRooms());
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onDeleteRoom(
    DeleteRoom event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.deleteRoom(event.id);
      emit(const RoomOperationSuccess('Xóa phòng học thành công'));
      add(const LoadRooms());
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  void _onFilterRooms(
    FilterRooms event,
    Emitter<RoomState> emit,
  ) {
    final currentState = state;
    if (currentState is RoomsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(filteredRooms: currentState.rooms));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.rooms.where((room) {
        return room.name.toLowerCase().contains(query) ||
               room.code.toLowerCase().contains(query) ||
               (room.location?.toLowerCase().contains(query) ?? false);
      }).toList();

      emit(currentState.copyWith(filteredRooms: filtered));
    }
  }
}