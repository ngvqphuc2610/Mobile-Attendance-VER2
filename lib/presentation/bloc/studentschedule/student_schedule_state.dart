
import 'package:equatable/equatable.dart';
import '../../../data/models/entity/student_schedule_entity.dart';

abstract class StudentScheduleState extends Equatable {
  const StudentScheduleState();

  @override
  List<Object?> get props => [];
}

class StudentScheduleInitial extends StudentScheduleState {}

class StudentScheduleLoading extends StudentScheduleState {}

class StudentSchedulesLoaded extends StudentScheduleState {
  final List<StudentScheduleEntity> schedules;
  final List<StudentScheduleEntity> filteredSchedules;

  const StudentSchedulesLoaded({
    required this.schedules,
    required this.filteredSchedules,
  });

  @override
  List<Object> get props => [schedules, filteredSchedules];

  StudentSchedulesLoaded copyWith({
    List<StudentScheduleEntity>? schedules,
    List<StudentScheduleEntity>? filteredSchedules,
  }) {
    return StudentSchedulesLoaded(
      schedules: schedules ?? this.schedules,
      filteredSchedules: filteredSchedules ?? this.filteredSchedules,
    );
  }
}

class StudentScheduleError extends StudentScheduleState {
  final String message;

  const StudentScheduleError(this.message);

  @override
  List<Object> get props => [message];
}
