import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class SectionScheduleService {
  static Future<List<Map<String, dynamic>>> fetchSectionSchedules({
    String? sectionId,
  }) async {
    final queryParams = <String, String>{};
    if (sectionId != null && sectionId.isNotEmpty) {
      queryParams['section_id'] = sectionId;
    }

    return ApiService.getList(
      ApiConstants.sectionSchedules,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
  }

  static Future<Map<String, dynamic>> createSectionSchedule({
    required String sectionId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomId,
  }) {
    return ApiService.create(ApiConstants.sectionSchedules, {
      'section_id': sectionId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room_id': roomId,
    });
  }

  static Future<Map<String, dynamic>> createSectionScheduleFromPayload(
    Map<String, dynamic> payload,
  ) {
    return ApiService.create(ApiConstants.sectionSchedules, payload);
  }

  static Future<Map<String, dynamic>> updateSectionSchedule({
    required String id,
    required String sectionId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomId,
  }) {
    return ApiService.update(ApiConstants.sectionSchedules, id, {
      'section_id': sectionId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room_id': roomId,
    });
  }

  static Future<Map<String, dynamic>> updateSectionScheduleFromPayload(
    String id,
    Map<String, dynamic> payload,
  ) {
    return ApiService.update(ApiConstants.sectionSchedules, id, payload);
  }

  static Future<Map<String, dynamic>> deleteSectionSchedule(String id) {
    return ApiService.delete(ApiConstants.sectionSchedules, id);
  }
}
