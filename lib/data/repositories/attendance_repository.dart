import '../models/entity/attendance_entity.dart';
import '../services/attendance_service.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceEntity>> getAttendances({
    String? userId,
    String? sectionId,
    String? sessionId,
    DateTime? fromDate,
    DateTime? toDate,
    AttendanceMethod? method,
    String? address,

  });
  
  Future<AttendanceEntity> createAttendance({
    required String userId,
    required AttendanceMethod method,
    double? confidenceScore,
    String? note,
    String? sectionId,
    String? sessionId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? address,
  });
  Future<void> deleteAttendance(String id);
  
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
    String? sessionId,
    DateTime? fromDate,
    DateTime? toDate,
    AttendanceMethod? method,
    String? address,
  }) async {
    try {
      return await AttendanceService.getAttendances(
        userId: userId,
        sectionId: sectionId,
        sessionId: sessionId,
        fromDate: fromDate,
        toDate: toDate,
        method: method,
        address: address,
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
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? address,
  }) async {
    try {
      return await AttendanceService.createAttendance(
        userId: userId,
        method: method,
        confidenceScore: confidenceScore,
        note: note,
        sectionId: sectionId,
        sessionId: sessionId,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        address: address,

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
  
  @override
  Future<void> deleteAttendance(String id) async {
    try {
      await AttendanceService.deleteAttendance(id);
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }
}

