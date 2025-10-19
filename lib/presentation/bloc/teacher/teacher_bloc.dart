import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/teacher_repository.dart';
import 'teacher_event.dart';
import 'teacher_state.dart';

class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  final TeacherRepository _repository;

  TeacherBloc({required TeacherRepository repository})
      : _repository = repository,
        super(TeacherInitial()) {
    on<LoadTeachers>(_onLoadTeachers);
    on<LoadTeacherById>(_onLoadTeacherById);
    on<CreateTeacher>(_onCreateTeacher);
    on<UpdateTeacher>(_onUpdateTeacher);
    on<DeleteTeacher>(_onDeleteTeacher);
    on<FilterTeachers>(_onFilterTeachers);
  }

  Future<void> _onLoadTeachers(
    LoadTeachers event,
    Emitter<TeacherState> emit,
  ) async {
    emit(TeacherLoading());

    try {
      final teachers = await _repository.getTeachers(
        facultyId: event.facultyId,
        search: event.search,
      );

      emit(TeachersLoaded(
        teachers: teachers,
        filteredTeachers: teachers,
      ));
    } catch (e) {
      emit(TeacherError(e.toString()));
    }
  }

  Future<void> _onLoadTeacherById(
    LoadTeacherById event,
    Emitter<TeacherState> emit,
  ) async {
    emit(TeacherLoading());

    try {
      final teacher = await _repository.getTeacherById(event.id);
      emit(TeacherLoaded(teacher));
    } catch (e) {
      emit(TeacherError(e.toString()));
    }
  }

  Future<void> _onCreateTeacher(
    CreateTeacher event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      await _repository.createTeacher(event.teacherDto);
      emit(const TeacherOperationSuccess('Tạo giảng viên thành công'));
      add(const LoadTeachers());
    } catch (e) {
      emit(TeacherError(e.toString()));
    }
  }

  Future<void> _onUpdateTeacher(
    UpdateTeacher event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      await _repository.updateTeacher(event.id, event.teacherDto);
      emit(const TeacherOperationSuccess('Cập nhật giảng viên thành công'));
      add(const LoadTeachers());
    } catch (e) {
      emit(TeacherError(e.toString()));
    }
  }

  Future<void> _onDeleteTeacher(
    DeleteTeacher event,
    Emitter<TeacherState> emit,
  ) async {
    try {
      await _repository.deleteTeacher(event.id);
      emit(const TeacherOperationSuccess('Xóa giảng viên thành công'));
      add(const LoadTeachers());
    } catch (e) {
      emit(TeacherError(e.toString()));
    }
  }

  void _onFilterTeachers(
    FilterTeachers event,
    Emitter<TeacherState> emit,
  ) {
    final currentState = state;
    if (currentState is TeachersLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(filteredTeachers: currentState.teachers));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.teachers.where((teacher) {
        final profile = teacher.profile;
        return profile?.fullName.toLowerCase().contains(query) == true ||
               profile?.code.toLowerCase().contains(query) == true ||
               profile?.email?.toLowerCase().contains(query) == true ||
               teacher.title?.toLowerCase().contains(query) == true;
      }).toList();

      emit(currentState.copyWith(filteredTeachers: filtered));
    }
  }
}