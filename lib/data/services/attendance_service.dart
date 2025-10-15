import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<List<Map<String, dynamic>>> getAttendance({
    String? userId,
    String? fromDate,
    String? toDate,
    String? method,
  }) async {
    final queryParams = <String, String>{};
    
    if (userId != null) queryParams['user_id'] = userId;
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;
    if (method != null) queryParams['method'] = method;
    
    return await ApiService.getList(ApiConstants.attendance, queryParams: queryParams);
  }
  
  static Future<Map<String, dynamic>> recordAttendance({
    required String userId,
    required String method,
    double? confidenceScore,
    String? note,
  }) async {
    return await ApiService.create(ApiConstants.attendance, {
      'user_id': userId,
      'method': method,
      'confidence_score': confidenceScore,
      'note': note,
    });
  }
  
  static Future<List<Map<String, dynamic>>> getAttendanceStats({
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, String>{};
    
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;
    
    return await ApiService.getList(ApiConstants.attendanceStats, queryParams: queryParams);
  }
}