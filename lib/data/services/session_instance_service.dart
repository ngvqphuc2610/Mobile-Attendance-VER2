import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class SessionInstanceService {
  static Future<List<Map<String, dynamic>>> fetchSessionInstances({
    String? sectionId,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (sectionId != null && sectionId.isNotEmpty) {
      queryParams['section_id'] = sectionId;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    return ApiService.getList(
      ApiConstants.sessionInstances,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
  }

  static Future<Map<String, dynamic>> createSessionInstance({
    required String sectionId,
    required String startsAt,
    required String endsAt,
    String status = 'planned',
    String? roomId,
  }) {
    return ApiService.create(ApiConstants.sessionInstances, {
      'section_id': sectionId,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'status': status,
      'room_id': roomId,
    });
  }

  static Future<Map<String, dynamic>> createSessionInstanceFromPayload(
    Map<String, dynamic> payload,
  ) {
    return ApiService.create(ApiConstants.sessionInstances, payload);
  }

  static Future<Map<String, dynamic>> updateSessionInstance({
    required String id,
    required String sectionId,
    required String startsAt,
    required String endsAt,
    String status = 'planned',
    String? roomId,
  }) {
    return ApiService.update(ApiConstants.sessionInstances, id, {
      'section_id': sectionId,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'status': status,
      'room_id': roomId,
    });
  }

  static Future<Map<String, dynamic>> updateSessionInstanceFromPayload(
    String id,
    Map<String, dynamic> payload,
  ) {
    return ApiService.update(ApiConstants.sessionInstances, id, payload);
  }

  static Future<Map<String, dynamic>> deleteSessionInstance(String id) {
    return ApiService.delete(ApiConstants.sessionInstances, id);
  }
  static Future<Map<String, dynamic>> fetchSessionInstanceById(String id) {
    return ApiService.getById(ApiConstants.sessionInstances, id);
  }
}
