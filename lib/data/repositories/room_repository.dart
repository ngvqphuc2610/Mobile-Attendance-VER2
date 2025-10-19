import '../models/entity/room_entity.dart';
import '../services/room_service.dart';

abstract class RoomRepository {
  Future<List<RoomEntity>> getRooms();
  Future<RoomEntity> createRoom({
    required String code,
    required String name,
    int? capacity,
    String? location,
  });
  Future<RoomEntity> updateRoom({
    required String id,
    required String code,
    required String name,
    int? capacity,
    String? location,
  });
  Future<void> deleteRoom(String id);
}

class RoomRepositoryImpl implements RoomRepository {
  @override
  Future<List<RoomEntity>> getRooms() async {
    try {
      return await RoomService.getRooms();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  @override
  Future<RoomEntity> createRoom({
    required String code,
    required String name,
    int? capacity,
    String? location,
  }) async {
    try {
      return await RoomService.createRoom(
        code: code,
        name: name,
        capacity: capacity,
        location: location,
      );
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  @override
  Future<RoomEntity> updateRoom({
    required String id,
    required String code,
    required String name,
    int? capacity,
    String? location,
  }) async {
    try {
      return await RoomService.updateRoom(
        id: id,
        code: code,
        name: name,
        capacity: capacity,
        location: location,
      );
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  @override
  Future<void> deleteRoom(String id) async {
    try {
      await RoomService.deleteRoom(id);
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }
}