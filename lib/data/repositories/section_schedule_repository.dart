import '../services/section_schedule_service.dart';

class SectionScheduleRepository {
  Future<List<Map<String, dynamic>>> getSectionSchedules({
    String? sectionId,
  }) async {
    return await SectionScheduleService.fetchSectionSchedules(
      sectionId: sectionId,
    );
  }

  Future<Map<String, dynamic>> createSectionScheduleFromPayload(
    Map<String, dynamic> payload,
  ) async {
    return await SectionScheduleService.createSectionScheduleFromPayload(payload);
  }

  Future<Map<String, dynamic>> updateSectionScheduleFromPayload(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return await SectionScheduleService.updateSectionScheduleFromPayload(id, payload);
  }

  Future<Map<String, dynamic>> deleteSectionSchedule(String id) async {
    return await SectionScheduleService.deleteSectionSchedule(id);
  }
}