import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/session_instance_repository.dart';
import 'session_instance_event.dart';
import 'session_instance_state.dart';

class SessionInstanceBloc extends Bloc<SessionInstanceEvent, SessionInstanceState> {
  final SessionInstanceRepository _repository;

  SessionInstanceBloc({required SessionInstanceRepository repository})
      : _repository = repository,
        super(SessionInstanceInitial()) {
    on<LoadSessionInstances>(_onLoadSessionInstances);
    on<CreateSessionInstance>(_onCreateSessionInstance);
    on<UpdateSessionInstance>(_onUpdateSessionInstance);
    on<DeleteSessionInstance>(_onDeleteSessionInstance);
    on<FilterSessionInstances>(_onFilterSessionInstances);
  }

  Future<void> _onLoadSessionInstances(
    LoadSessionInstances event,
    Emitter<SessionInstanceState> emit,
  ) async {
    emit(SessionInstanceLoading());

    try {
      final instances = await _repository.getSessionInstances(
        sectionId: event.sectionId,
      );
      emit(SessionInstancesLoaded(
        instances: instances,
        filteredInstances: instances,
      ));
    } catch (e) {
      emit(SessionInstanceError(e.toString()));
    }
  }

  Future<void> _onCreateSessionInstance(
    CreateSessionInstance event,
    Emitter<SessionInstanceState> emit,
  ) async {
    try {
      await _repository.createSessionInstanceFromPayload(event.payload);
      emit(const SessionInstanceOperationSuccess('Tạo phiên học thành công'));
      add(const LoadSessionInstances());
    } catch (e) {
      emit(SessionInstanceError(e.toString()));
    }
  }

  Future<void> _onUpdateSessionInstance(
    UpdateSessionInstance event,
    Emitter<SessionInstanceState> emit,
  ) async {
    try {
      await _repository.updateSessionInstanceFromPayload(event.id, event.payload);
      emit(const SessionInstanceOperationSuccess('Cập nhật phiên học thành công'));
      add(const LoadSessionInstances());
    } catch (e) {
      emit(SessionInstanceError(e.toString()));
    }
  }

  Future<void> _onDeleteSessionInstance(
    DeleteSessionInstance event,
    Emitter<SessionInstanceState> emit,
  ) async {
    try {
      await _repository.deleteSessionInstance(event.id);
      emit(const SessionInstanceOperationSuccess('Xóa phiên học thành công'));
      add(const LoadSessionInstances());
    } catch (e) {
      emit(SessionInstanceError(e.toString()));
    }
  }

  void _onFilterSessionInstances(
    FilterSessionInstances event,
    Emitter<SessionInstanceState> emit,
  ) {
    final currentState = state;
    if (currentState is SessionInstancesLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(
          filteredInstances: currentState.instances,
        ));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.instances.where((instance) {
        final sectionCode = instance['section_code']?.toString().toLowerCase() ?? '';
        final sectionId = instance['section_id']?.toString().toLowerCase() ?? '';
        final roomCode = instance['room_code']?.toString().toLowerCase() ?? '';
        final roomId = instance['room_id']?.toString().toLowerCase() ?? '';
        final status = instance['status']?.toString().toLowerCase() ?? '';
        final subjectName = instance['subject_name']?.toString().toLowerCase() ?? '';

        return sectionCode.contains(query) ||
            sectionId.contains(query) ||
            roomCode.contains(query) ||
            roomId.contains(query) ||
            status.contains(query) ||
            subjectName.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredInstances: filtered));
    }
  }
}
