import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/faculty_repository.dart';
import 'faculty_event.dart';
import 'faculty_state.dart';

class FacultyBloc extends Bloc<FacultyEvent, FacultyState> {
  final FacultyRepository _repository;

  FacultyBloc({required FacultyRepository repository})
      : _repository = repository,
        super(FacultyInitial()) {
    on<LoadFaculties>(_onLoadFaculties);
    on<CreateFaculty>(_onCreateFaculty);
    on<UpdateFaculty>(_onUpdateFaculty);
    on<DeleteFaculty>(_onDeleteFaculty);
    on<FilterFaculties>(_onFilterFaculties);
  }

  Future<void> _onLoadFaculties(
    LoadFaculties event,
    Emitter<FacultyState> emit,
  ) async {
    emit(FacultyLoading());

    try {
      final faculties = await _repository.getFaculties();
      emit(FacultiesLoaded(
        faculties: faculties,
        filteredFaculties: faculties,
      ));
    } catch (e) {
      emit(FacultyError(e.toString()));
    }
  }

  Future<void> _onCreateFaculty(
    CreateFaculty event,
    Emitter<FacultyState> emit,
  ) async {
    try {
      await _repository.createFaculty(
        code: event.code,
        name: event.name,
      );
      emit(const FacultyOperationSuccess('Thêm khoa thành công'));
      add(const LoadFaculties());
    } catch (e) {
      emit(FacultyError(e.toString()));
    }
  }

  Future<void> _onUpdateFaculty(
    UpdateFaculty event,
    Emitter<FacultyState> emit,
  ) async {
    try {
      await _repository.updateFaculty(
        id: event.id,
        code: event.code,
        name: event.name,
      );
      emit(const FacultyOperationSuccess('Cập nhật khoa thành công'));
      add(const LoadFaculties());
    } catch (e) {
      emit(FacultyError(e.toString()));
    }
  }

  Future<void> _onDeleteFaculty(
    DeleteFaculty event,
    Emitter<FacultyState> emit,
  ) async {
    try {
      await _repository.deleteFaculty(event.id);
      emit(const FacultyOperationSuccess('Xóa khoa thành công'));
      add(const LoadFaculties());
    } catch (e) {
      emit(FacultyError(e.toString()));
    }
  }

  void _onFilterFaculties(
    FilterFaculties event,
    Emitter<FacultyState> emit,
  ) {
    final currentState = state;
    if (currentState is FacultiesLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(filteredFaculties: currentState.faculties));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.faculties.where((faculty) {
        return faculty.name.toLowerCase().contains(query) ||
               faculty.code.toLowerCase().contains(query);
      }).toList();

      emit(currentState.copyWith(filteredFaculties: filtered));
    }
  }
}