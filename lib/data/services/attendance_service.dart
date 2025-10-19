import '../../core/constants/api_constants.dart';
import '../models/entity/attendance_entity.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<List<AttendanceEntity>> getAttendances({
    String? userId,
    String? sectionId,
    DateTime? fromDate,
    DateTime? toDate,
    AttendanceMethod? method,
  }) async {
    final queryParams = <String, String>{};

    if (userId != null) queryParams['user_id'] = userId;
    if (sectionId != null) queryParams['section_id'] = sectionId;
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
    if (method != null) queryParams['method'] = method.name;

    final response = await ApiService.getList(
      ApiConstants.attendance,
      queryParams: queryParams,
    );

    return response.map((json) => AttendanceEntity.fromJson(json)).toList();
  }

  static Future<AttendanceEntity> createAttendance({
    required String userId,
    required AttendanceMethod method,
    double? confidenceScore,
    String? note,
    String? sectionId,
    String? sessionId,
  }) async {
    final response = await ApiService.create(ApiConstants.attendance, {
      'user_id': userId,
      'method': method.name,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (note != null) 'note': note,
      if (sectionId != null) 'section_id': sectionId,
      if (sessionId != null) 'session_id': sessionId,
    });
    return AttendanceEntity.fromJson(response);
  }

  static Future<Map<String, dynamic>> getAttendanceStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{};

    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

    return await ApiService.getWithParams(
      ApiConstants.attendanceStats,
      queryParams: queryParams,
    );
  }
}
