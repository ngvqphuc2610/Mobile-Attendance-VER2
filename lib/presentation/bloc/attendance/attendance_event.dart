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
  final DateTime? fromDate;
  final DateTime? toDate;
  final AttendanceMethod? method;

  const LoadAttendances({
    this.userId,
    this.sectionId,
    this.fromDate,
    this.toDate,
    this.method,
  });

  @override
  List<Object?> get props => [userId, sectionId, fromDate, toDate, method];
}

class CreateAttendance extends AttendanceEvent {
  final String userId;
  final AttendanceMethod method;
  final double? confidenceScore;
  final String? note;
  final String? sectionId;
  final String? sessionId;

  const CreateAttendance({
    required this.userId,
    required this.method,
    this.confidenceScore,
    this.note,
    this.sectionId,
    this.sessionId,
  });

  @override
  List<Object?> get props => [userId, method, confidenceScore, note, sectionId, sessionId];
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
class DeleteAttendance extends AttendanceEvent {
  final String attendanceId;

  const DeleteAttendance(this.attendanceId);

  @override
  List<Object> get props => [attendanceId];
}