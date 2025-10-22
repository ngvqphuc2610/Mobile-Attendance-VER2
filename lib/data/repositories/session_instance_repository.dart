import '../services/session_instance_service.dart';

class SessionInstanceRepository {
  Future<List<Map<String, dynamic>>> getSessionInstances({
    String? sectionId,
  }) async {
    return await SessionInstanceService.fetchSessionInstances(
      sectionId: sectionId,
    );
  }

  Future<Map<String, dynamic>> createSessionInstanceFromPayload(
    Map<String, dynamic> payload,
  ) async {
    return await SessionInstanceService.createSessionInstanceFromPayload(
      payload,
    );
  }

  Future<Map<String, dynamic>> updateSessionInstanceFromPayload(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return await SessionInstanceService.updateSessionInstanceFromPayload(
      id,
      payload,
    );
  }

  Future<Map<String, dynamic>> deleteSessionInstance(String id) async {
    return await SessionInstanceService.deleteSessionInstance(id);
  }

  Future<Map<String, dynamic>> getById(String id) {
    return SessionInstanceService.fetchSessionInstanceById(id);
  }
}
