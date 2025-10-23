
import '../../core/constants/api_constants.dart';
import '../models/entity/student_schedule_entity.dart';
import 'api_service.dart';

class StudentScheduleService {
  static Future<List<StudentScheduleEntity>> fetchStudentSchedules({
    required String studentId,
    DateTime? from,
    DateTime? to,
    int? semester,
    int? year,
  }) async {
    var endpoint = '${ApiConstants.students}/$studentId/schedules';

    final query = <String, String>{};
    if (from != null) {
      query['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      query['to'] = to.toUtc().toIso8601String();
    }
    if (semester != null) {
      query['semester'] = semester.toString();
    }
    if (year != null) {
      query['year'] = year.toString();
    }

    if (query.isNotEmpty) {
      final qs = Uri(queryParameters: query).query;
      endpoint = '$endpoint?$qs';
    }

    final response = await ApiService.getList(endpoint);

    return response
        .map((json) => StudentScheduleEntity.fromJson(json))
        .toList(growable: false);
  }
}
