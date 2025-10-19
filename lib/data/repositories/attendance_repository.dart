import '../models/entity/attendance_entity.dart';
import '../services/attendance_service.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceEntity>> getAttendances({
    String? userId,
    String? sectionId,
    DateTime? fromDate,
    DateTime? toDate,
    AttendanceMethod? method,
  });
  
  Future<AttendanceEntity> createAttendance({
    required String userId,
    required AttendanceMethod method,
    double? confidenceScore,
    String? note,
    String? sectionId,
    String? sessionId,
  });
  
  Future<Map<String, dynamic>> getAttendanceStats({
    DateTime? fromDate,
    DateTime? toDate,
  });
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  @override
  Future<List<AttendanceEntity>> getAttendances({
    String? userId,
    String? sectionId,
    DateTime? fromDate,
    DateTime? toDate,
    AttendanceMethod? method,
  }) async {
    try {
      return await AttendanceService.getAttendances(
        userId: userId,
        sectionId: sectionId,
        fromDate: fromDate,
        toDate: toDate,
        method: method,
      );
    } catch (e) {
      throw Exception('Failed to fetch attendances: $e');
    }
  }

  @override
  Future<AttendanceEntity> createAttendance({
    required String userId,
    required AttendanceMethod method,
    double? confidenceScore,
    String? note,
    String? sectionId,
    String? sessionId,
  }) async {
    try {
      return await AttendanceService.createAttendance(
        userId: userId,
        method: method,
        confidenceScore: confidenceScore,
        note: note,
        sectionId: sectionId,
        sessionId: sessionId,
      );
    } catch (e) {
      throw Exception('Failed to create attendance: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats({
    DateTime? fromDate,
    DateTime? toDate,
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

