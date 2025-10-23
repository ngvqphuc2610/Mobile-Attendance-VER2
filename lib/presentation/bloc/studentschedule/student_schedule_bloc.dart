
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/student_schedule_repository.dart';
import 'student_schedule_event.dart';
import 'student_schedule_state.dart';
import '../../../data/models/entity/student_schedule_entity.dart';

class StudentScheduleBloc extends Bloc<StudentScheduleEvent, StudentScheduleState> {
  final StudentScheduleRepository _repository;

  StudentScheduleBloc({required StudentScheduleRepository repository})
      : _repository = repository,
        super(StudentScheduleInitial()) {
    on<LoadStudentSchedules>(_onLoadStudentSchedules);
    on<FilterStudentSchedules>(_onFilterStudentSchedules);
  }

  Future<void> _onLoadStudentSchedules(
    LoadStudentSchedules event,
    Emitter<StudentScheduleState> emit,
  ) async {
    emit(StudentScheduleLoading());

    try {
      final schedules = await _repository.getStudentSchedules(
        studentId: event.studentId,
        from: event.from,
        to: event.to,
        semester: event.semester,
        year: event.year,
      );
      emit(StudentSchedulesLoaded(
        schedules: schedules,
        filteredSchedules: schedules,
      ));
    } catch (e) {
      emit(StudentScheduleError(e.toString()));
    }
  }

  void _onFilterStudentSchedules(
    FilterStudentSchedules event,
    Emitter<StudentScheduleState> emit,
  ) {
    final current = state;
    if (current is! StudentSchedulesLoaded) return;

    var filtered = current.schedules;

    if (event.semester != null && event.year != null) {
      filtered = filtered
          .where((s) => s.semester == event.semester && s.year == event.year)
          .toList(growable: false);
    } else if (event.semester != null) {
      filtered = filtered
          .where((s) => s.semester == event.semester)
          .toList(growable: false);
    } else if (event.year != null) {
      filtered =
          filtered.where((s) => s.year == event.year).toList(growable: false);
    }

    if (event.from != null && event.to != null) {
      final from = event.from!;
      final to = event.to!;
      filtered = filtered.where((schedule) {
        final date = schedule.startsAt ??
            DateTime(
              from.year,
              from.month,
              from.day,
            );
        return !date.isBefore(from) && !date.isAfter(to);
      }).toList(growable: false);
    }

    emit(current.copyWith(filteredSchedules: filtered));
  }
}
