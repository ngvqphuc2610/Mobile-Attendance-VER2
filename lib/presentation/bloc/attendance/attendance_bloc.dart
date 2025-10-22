import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';
import '../../../data/models/entity/attendance_entity.dart';
import '../../../core/helpers/location_helper.dart';

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
    on<LoadAttendancesBySession>(_onLoadAttendancesBySession);
    on<ApplyAttendanceFilters>(_onApplyAttendanceFilters);
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
        sessionId: event.sessionId,
        fromDate: event.fromDate,
        toDate: event.toDate,
        method: event.method,
        address: event.address,
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
        latitude: event.latitude,
        longitude: event.longitude,
        accuracyMeters: event.accuracyMeters,
        address: event.address,
      );

      emit(const AttendanceOperationSuccess('Điểm danh thành công'));
      add(
        LoadAttendances(sectionId: event.sectionId, sessionId: event.sessionId),
      );
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
    if (currentState is! AttendancesLoaded) return;

    final raw = event.query.trim();
    if (raw.isEmpty) {
      emit(
        currentState.copyWith(filteredAttendances: currentState.attendances),
      );
      return;
    }

    // ── NEW: parse "role:teacher id:xxx" / "role:student id:yyy"
    final lower = raw.toLowerCase();
    final roleMatch = RegExp(r'role\s*:\s*(teacher|student)').firstMatch(lower);
    final idMatch = RegExp(r'id\s*:\s*([a-z0-9\-\_]+)').firstMatch(lower);
    final role = roleMatch?.group(1); // teacher | student
    final id = idMatch?.group(1); // chuỗi id

    List<AttendanceEntity> filtered = currentState.attendances;

    bool appliedStructured = false;

    if (role == 'student') {
      // Ưu tiên lọc theo userId nếu có; fallback theo code/name
      appliedStructured = true;
      filtered = filtered.where((a) {
        final okId = id == null ? true : (a.userId == id);
        final okText = true; // có thể AND thêm text tự do nếu muốn
        return okId && okText;
      }).toList();
    } else if (role == 'teacher') {
      // Chỉ dùng được nếu entity có thông tin teacher
      // Nếu AttendanceEntity chưa có teacherId/teacherName -> đoạn này sẽ chỉ lọc theo text thường.
      // Bạn có thể thêm field vào entity để lọc chính xác.
      appliedStructured = true;
    }

    if (!appliedStructured) {
      // Fallback: text search cũ
      final q = lower;
      filtered = currentState.attendances.where((a) {
        return (a.userFullName?.toLowerCase().contains(q) == true) ||
            (a.userCode?.toLowerCase().contains(q) == true) ||
            (a.method.name.toLowerCase().contains(q)) ||
            (a.note?.toLowerCase().contains(q) == true) ||
            (a.address?.toLowerCase().contains(q) == true);
      }).toList();
    }

    emit(currentState.copyWith(filteredAttendances: filtered));
  }

  Future<void> _onDeleteAttendance(
    DeleteAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // ❌ BỎ GỌI TRÙNG LẶP
      await _repository.deleteAttendance(event.attendanceId);

      emit(const AttendanceOperationSuccess('Xóa điểm danh thành công'));
      add(
        LoadAttendances(sectionId: event.sectionId, sessionId: event.sessionId),
      );
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onLoadAttendancesBySession(
    LoadAttendancesBySession event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      // ✅ SỬA NHẦM: phải truyền sessionId
      final attendances = await _repository.getAttendances(
        sessionId: event.sessionId,
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
  Future<void> _onApplyAttendanceFilters( 
    ApplyAttendanceFilters event,
    Emitter<AttendanceState> emit,
  ) async {
    add(
      LoadAttendances(
        userId: event.studentId,
        sectionId: event.sectionId,
        sessionId: event.sessionId,
        fromDate: event.fromDate,
        toDate: event.toDate,
        method: event.method,
        address: event.address,
      ),
    );
  }
}
