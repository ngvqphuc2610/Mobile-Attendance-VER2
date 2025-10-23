
import 'package:equatable/equatable.dart';

abstract class StudentScheduleEvent extends Equatable {
  const StudentScheduleEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentSchedules extends StudentScheduleEvent {
  final String studentId;
  final DateTime? from;
  final DateTime? to;
  final int? semester;
  final int? year;

  const LoadStudentSchedules({
    required this.studentId,
    this.from,
    this.to,
    this.semester,
    this.year,
  });

  @override
  List<Object?> get props => [studentId, from, to, semester, year];
}

class LoadStudentScheduleById extends StudentScheduleEvent {
  final String id;

  const LoadStudentScheduleById(this.id);

  @override
  List<Object> get props => [id];
}

class FilterStudentSchedules extends StudentScheduleEvent {
  final DateTime? from;
  final DateTime? to;
  final int? semester;
  final int? year;

  const FilterStudentSchedules({
    this.from,
    this.to,
    this.semester,
    this.year,
  });

  @override
  List<Object?> get props => [from, to, semester, year];
}
