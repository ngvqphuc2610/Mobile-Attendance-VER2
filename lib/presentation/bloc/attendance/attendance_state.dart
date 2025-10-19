import 'package:equatable/equatable.dart';
import '../../../data/models/entity/attendance_entity.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendancesLoaded extends AttendanceState {
  final List<AttendanceEntity> attendances;
  final List<AttendanceEntity> filteredAttendances;

  const AttendancesLoaded({
    required this.attendances,
    required this.filteredAttendances,
  });

  @override
  List<Object> get props => [attendances, filteredAttendances];

  AttendancesLoaded copyWith({
    List<AttendanceEntity>? attendances,
    List<AttendanceEntity>? filteredAttendances,
  }) {
    return AttendancesLoaded(
      attendances: attendances ?? this.attendances,
      filteredAttendances: filteredAttendances ?? this.filteredAttendances,
    );
  }
}

class AttendanceStatsLoaded extends AttendanceState {
  final Map<String, dynamic> stats;

  const AttendanceStatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object> get props => [message];
}

class AttendanceOperationSuccess extends AttendanceState {
  final String message;

  const AttendanceOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}