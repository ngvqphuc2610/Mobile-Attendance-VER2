import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceBloc({required AttendanceRepository repository})
    : _repository = repository,
      super(AttendanceInitial()) {
    on<LoadAttendances>(_onLoadAttendances);
    on<CreateAttendance>(_onCreateAttendance);
    on<LoadAttendanceStats>(_onLoadAttendanceStats);
    on<FilterAttendances>(_onFilterAttendances);
    on<DeleteAttendance>(_onDeleteAttendance);
  }

  Future<void> _onLoadAttendances(
    LoadAttendances event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final attendances = await _repository.getAttendances(
        userId: event.userId,
        sectionId: event.sectionId,
        fromDate: event.fromDate,
        toDate: event.toDate,
        method: event.method,
      );

      emit(
        AttendancesLoaded(
          attendances: attendances,
          filteredAttendances: attendances,
        ),
      );
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onCreateAttendance(
    CreateAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _repository.createAttendance(
        userId: event.userId,
        method: event.method,
        confidenceScore: event.confidenceScore,
        note: event.note,
        sectionId: event.sectionId,
        sessionId: event.sessionId,
      );

      emit(const AttendanceOperationSuccess('Điểm danh thành công'));
      add(const LoadAttendances());
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onLoadAttendanceStats(
    LoadAttendanceStats event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final stats = await _repository.getAttendanceStats(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      emit(AttendanceStatsLoaded(stats));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  void _onFilterAttendances(
    FilterAttendances event,
    Emitter<AttendanceState> emit,
  ) {
    final currentState = state;
    if (currentState is AttendancesLoaded) {
      if (event.query.trim().isEmpty) {
        emit(
          currentState.copyWith(filteredAttendances: currentState.attendances),
        );
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.attendances.where((attendance) {
        return (attendance.userFullName?.toLowerCase().contains(query) ==
                true) ||
            (attendance.userCode?.toLowerCase().contains(query) == true) ||
            (attendance.method.name.toLowerCase().contains(query)) ||
            (attendance.note?.toLowerCase().contains(query) == true);
      }).toList();

      emit(currentState.copyWith(filteredAttendances: filtered));
    }
  }

  Future<void> _onDeleteAttendance(
    DeleteAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _repository.deleteAttendance(event.attendanceId);
      emit(const AttendanceOperationSuccess('Xóa điểm danh thành công'));
      add(const LoadAttendances());
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }
}
