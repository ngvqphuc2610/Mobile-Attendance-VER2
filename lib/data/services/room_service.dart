
import '../../core/constants/api_constants.dart';
import '../models/entity/room_entity.dart';
import 'api_service.dart';

class RoomService {
  static Future<List<RoomEntity>> getRooms() async {
    final response = await ApiService.getList(ApiConstants.rooms);
    return response.map((json) => RoomEntity.fromJson(json)).toList();
  }

  static Future<RoomEntity> createRoom({
    required String code,
    required String name,
    int? capacity,
    String? location,
  }) async {
    final response = await ApiService.create(
      ApiConstants.rooms,
      {
        'code': code,
        'name': name,
        if (capacity != null) 'capacity': capacity,
        if (location != null) 'location': location,
      },
    );
    return RoomEntity.fromJson(response);
  }

  static Future<RoomEntity> updateRoom({
    required String id,
    required String code,
    required String name,
    int? capacity,
    String? location,
  }) async {
    final response = await ApiService.update(
      ApiConstants.rooms,
      id,
      {
        'code': code,
        'name': name,
        if (capacity != null) 'capacity': capacity,
        if (location != null) 'location': location,
      },
    );
    return RoomEntity.fromJson(response);
  }

  static Future<void> deleteRoom(String id) async {
    await ApiService.delete(ApiConstants.rooms, id);
  }
}
