import 'package:equatable/equatable.dart';

abstract class SectionScheduleState extends Equatable {
  const SectionScheduleState();

  @override
  List<Object?> get props => [];
}

class SectionScheduleInitial extends SectionScheduleState {}

class SectionScheduleLoading extends SectionScheduleState {}

class SectionSchedulesLoaded extends SectionScheduleState {
  final List<Map<String, dynamic>> schedules;
  final List<Map<String, dynamic>> filteredSchedules;

  const SectionSchedulesLoaded({
    required this.schedules,
    required this.filteredSchedules,
  });

  SectionSchedulesLoaded copyWith({
    List<Map<String, dynamic>>? schedules,
    List<Map<String, dynamic>>? filteredSchedules,
  }) {
    return SectionSchedulesLoaded(
      schedules: schedules ?? this.schedules,
      filteredSchedules: filteredSchedules ?? this.filteredSchedules,
    );
  }

  @override
  List<Object> get props => [schedules, filteredSchedules];
}

class SectionScheduleError extends SectionScheduleState {
  final String message;

  const SectionScheduleError(this.message);

  @override
  List<Object> get props => [message];
}

class SectionScheduleOperationSuccess extends SectionScheduleState {
  final String message;

  const SectionScheduleOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

