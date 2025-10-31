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
      
      // ✅ Apply filter ngay sau khi load
      final filtered = _applyFilters(
        schedules,
        from: event.from,
        to: event.to,
        semester: event.semester,
        year: event.year,
      );
      
      emit(StudentSchedulesLoaded(
        schedules: schedules,
        filteredSchedules: filtered,
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

    final filtered = _applyFilters(
      current.schedules,
      from: event.from,
      to: event.to,
      semester: event.semester,
      year: event.year,
    );

    emit(current.copyWith(filteredSchedules: filtered));
  }

  // ✅ Helper method để tránh duplicate code
  List<StudentScheduleEntity> _applyFilters(
    List<StudentScheduleEntity> schedules, {
    DateTime? from,
    DateTime? to,
    int? semester,
    int? year,
  }) {
    var filtered = schedules;

    // Filter by semester and year
    if (semester != null && year != null) {
      filtered = filtered
          .where((s) => s.semester == semester && s.year == year)
          .toList();
    } else if (semester != null) {
      filtered = filtered
          .where((s) => s.semester == semester)
          .toList();
    } else if (year != null) {
      filtered = filtered
          .where((s) => s.year == year)
          .toList();
    }

    // Filter by date range
    if (from != null && to != null) {
      filtered = filtered.where((schedule) {
        // ✅ Chỉ giữ schedules có startsAt hợp lệ
        if (schedule.startsAt == null) return false;
        
        final date = schedule.startsAt!;
        return !date.isBefore(from) && !date.isAfter(to);
      }).toList();
    }

    return filtered;
  }
}