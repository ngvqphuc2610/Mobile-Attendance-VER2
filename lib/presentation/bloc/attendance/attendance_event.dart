import 'package:equatable/equatable.dart';
import '../../../data/models/entity/attendance_entity.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendances extends AttendanceEvent {
  final String? userId;
  final String? sectionId;
  final String? sessionId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final AttendanceMethod? method;

  const LoadAttendances({
    this.userId,
    this.sectionId,
    this.sessionId,
    this.fromDate,
    this.toDate,
    this.method,
  });

  @override
  List<Object?> get props => [userId, sectionId, sessionId, fromDate, toDate, method];
}

class CreateAttendance extends AttendanceEvent {
  final String userId;
  final AttendanceMethod method;
  final double? confidenceScore;
  final String? note;
  final String sectionId;
  final String? sessionId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? address;

  const CreateAttendance({
    required this.userId,
    required this.method,
    this.confidenceScore,
    this.note,
    required this.sectionId,
    this.sessionId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.address,
  });

  @override
  List<Object?> get props => [userId, method, confidenceScore, note, sectionId, sessionId, latitude, longitude, accuracyMeters, address];
}

class LoadAttendanceStats extends AttendanceEvent {
  final DateTime? fromDate;
  final DateTime? toDate;

  const LoadAttendanceStats({this.fromDate, this.toDate});

  @override
  List<Object?> get props => [fromDate, toDate];
}

class FilterAttendances extends AttendanceEvent {
  final String query;

  const FilterAttendances(this.query);

  @override
  List<Object> get props => [query];
}

/// Đổi sang tham số đặt tên để đồng nhất cách gọi:
/// DeleteAttendance(attendanceId: '...', sectionId: '...', sessionId: '...')
class DeleteAttendance extends AttendanceEvent {
  final String attendanceId;
  final String? sectionId;
  final String? sessionId;

  const DeleteAttendance({
    required this.attendanceId,
    this.sectionId,
    this.sessionId,
  });

  @override
  List<Object?> get props => [attendanceId, sectionId, sessionId];
}

class LoadAttendancesBySession extends AttendanceEvent {
  final String sessionId;

  const LoadAttendancesBySession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}
