import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/section_schedule_repository.dart';
import 'section_schedule_event.dart';
import 'section_schedule_state.dart';

class SectionScheduleBloc extends Bloc<SectionScheduleEvent, SectionScheduleState> {
  final SectionScheduleRepository _repository;

  SectionScheduleBloc({required SectionScheduleRepository repository})
      : _repository = repository,
        super(SectionScheduleInitial()) {
    on<LoadSectionSchedules>(_onLoadSectionSchedules);
    on<CreateSectionSchedule>(_onCreateSectionSchedule);
    on<UpdateSectionSchedule>(_onUpdateSectionSchedule);
    on<DeleteSectionSchedule>(_onDeleteSectionSchedule);
    on<FilterSectionSchedules>(_onFilterSectionSchedules);
  }

  Future<void> _onLoadSectionSchedules(
    LoadSectionSchedules event,
    Emitter<SectionScheduleState> emit,
  ) async {
    emit(SectionScheduleLoading());

    try {
      final schedules = await _repository.getSectionSchedules(
        sectionId: event.sectionId,
      );
      emit(SectionSchedulesLoaded(
        schedules: schedules,
        filteredSchedules: schedules,
      ));
    } catch (e) {
      emit(SectionScheduleError(e.toString()));
    }
  }

  Future<void> _onCreateSectionSchedule(
    CreateSectionSchedule event,
    Emitter<SectionScheduleState> emit,
  ) async {
    try {
      await _repository.createSectionScheduleFromPayload(event.payload);
      emit(const SectionScheduleOperationSuccess('Tạo lịch học thành công'));
      add(const LoadSectionSchedules());
    } catch (e) {
      emit(SectionScheduleError(e.toString()));
    }
  }

  Future<void> _onUpdateSectionSchedule(
    UpdateSectionSchedule event,
    Emitter<SectionScheduleState> emit,
  ) async {
    try {
      await _repository.updateSectionScheduleFromPayload(event.id, event.payload);
      emit(const SectionScheduleOperationSuccess('Cập nhật lịch học thành công'));
      add(const LoadSectionSchedules());
    } catch (e) {
      emit(SectionScheduleError(e.toString()));
    }
  }

  Future<void> _onDeleteSectionSchedule(
    DeleteSectionSchedule event,
    Emitter<SectionScheduleState> emit,
  ) async {
    try {
      await _repository.deleteSectionSchedule(event.id);
      emit(const SectionScheduleOperationSuccess('Xóa lịch học thành công'));
      add(const LoadSectionSchedules());
    } catch (e) {
      emit(SectionScheduleError(e.toString()));
    }
  }

  void _onFilterSectionSchedules(
    FilterSectionSchedules event,
    Emitter<SectionScheduleState> emit,
  ) {
    final currentState = state;
    if (currentState is SectionSchedulesLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(
          filteredSchedules: currentState.schedules,
        ));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.schedules.where((schedule) {
        final sectionCode = schedule['section_code']?.toString().toLowerCase() ?? '';
        final sectionId = schedule['section_id']?.toString().toLowerCase() ?? '';
        final roomCode = schedule['room_code']?.toString().toLowerCase() ?? '';
        final roomId = schedule['room_id']?.toString().toLowerCase() ?? '';
        final subjectName = schedule['subject_name']?.toString().toLowerCase() ?? '';
        final subjectCode = schedule['subject_code']?.toString().toLowerCase() ?? '';

        return sectionCode.contains(query) ||
            sectionId.contains(query) ||
            roomCode.contains(query) ||
            roomId.contains(query) ||
            subjectName.contains(query) ||
            subjectCode.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredSchedules: filtered));
    }
  }
}