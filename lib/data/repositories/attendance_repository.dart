import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceRepository {
  Future<List<AttendanceModel>> getAttendance({
    String? userId,
    String? fromDate,
    String? toDate,
    String? method,
  }) async {
    try {
      final data = await AttendanceService.getAttendance(
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
        method: method,
      );
      
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  Future<void> recordAttendance({
    required String userId,
    required String method,
    double? confidenceScore,
    String? note,
  }) async {
    try {
      await AttendanceService.recordAttendance(
        userId: userId,
        method: method,
        confidenceScore: confidenceScore,
        note: note,
      );
    } catch (e) {
      throw Exception('Failed to record attendance: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceStats({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      return await AttendanceService.getAttendanceStats(
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      throw Exception('Failed to fetch attendance stats: $e');
    }
  }
}