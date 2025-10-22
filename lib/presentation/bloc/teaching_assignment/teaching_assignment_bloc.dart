import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/teaching_assignment_repository.dart';
import 'teaching_assignment_event.dart';
import 'teaching_assignment_state.dart';

class TeachingAssignmentBloc extends Bloc<TeachingAssignmentEvent, TeachingAssignmentState> {
  final TeachingAssignmentRepository _repository;

  TeachingAssignmentBloc({required TeachingAssignmentRepository repository})
      : _repository = repository,
        super(TeachingAssignmentInitial()) {
    on<LoadTeachingAssignments>(_onLoadTeachingAssignments);
    on<CreateTeachingAssignment>(_onCreateTeachingAssignment);
    on<UpdateTeachingAssignment>(_onUpdateTeachingAssignment);
    on<DeleteTeachingAssignment>(_onDeleteTeachingAssignment);
    on<FilterTeachingAssignments>(_onFilterTeachingAssignments);
  }

  Future<void> _onLoadTeachingAssignments(
    LoadTeachingAssignments event,
    Emitter<TeachingAssignmentState> emit,
  ) async {
    emit(TeachingAssignmentLoading());

    try {
      // ✅ Sử dụng teacherId từ event
      final assignments = await _repository.getTeachingAssignments(
        teacherId: event.teacherId,
      );
      
      emit(TeachingAssignmentsLoaded(
        assignments: assignments,
        filteredAssignments: assignments,
      ));
    } catch (e) {
      emit(TeachingAssignmentError(e.toString()));
    }
  }

  Future<void> _onCreateTeachingAssignment(
    CreateTeachingAssignment event,
    Emitter<TeachingAssignmentState> emit,
  ) async {
    try {
      await _repository.createTeachingAssignmentFromPayload(event.payload);
      emit(const TeachingAssignmentOperationSuccess('Phân công giảng dạy thành công'));
      // Reload tất cả (dành cho admin)
      add(const LoadTeachingAssignments());
    } catch (e) {
      emit(TeachingAssignmentError(e.toString()));
    }
  }

  Future<void> _onUpdateTeachingAssignment(
    UpdateTeachingAssignment event,
    Emitter<TeachingAssignmentState> emit,
  ) async {
    try {
      await _repository.updateTeachingAssignmentFromPayload(event.id, event.payload);
      emit(const TeachingAssignmentOperationSuccess('Cập nhật phân công thành công'));
      // Reload tất cả (dành cho admin)
      add(const LoadTeachingAssignments());
    } catch (e) {
      emit(TeachingAssignmentError(e.toString()));
    }
  }

  Future<void> _onDeleteTeachingAssignment(
    DeleteTeachingAssignment event,
    Emitter<TeachingAssignmentState> emit,
  ) async {
    try {
      await _repository.deleteTeachingAssignment(event.id);
      emit(const TeachingAssignmentOperationSuccess('Xóa phân công thành công'));
      // Reload tất cả (dành cho admin)
      add(const LoadTeachingAssignments());
    } catch (e) {
      emit(TeachingAssignmentError(e.toString()));
    }
  }

  void _onFilterTeachingAssignments(
    FilterTeachingAssignments event,
    Emitter<TeachingAssignmentState> emit,
  ) {
    final currentState = state;
    if (currentState is TeachingAssignmentsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(
          filteredAssignments: currentState.assignments,
        ));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.assignments.where((assignment) {
        final teacherName = assignment['teacher_name']?.toString().toLowerCase() ?? '';
        final subjectName = assignment['subject_name']?.toString().toLowerCase() ?? '';
        final sectionCode = assignment['section_code']?.toString().toLowerCase() ?? '';
        final subjectCode = assignment['subject_code']?.toString().toLowerCase() ?? '';
        final year = assignment['year']?.toString().toLowerCase() ?? '';
        final semester = assignment['semester']?.toString().toLowerCase() ?? '';
        final role = assignment['role']?.toString().toLowerCase() ?? '';

        return teacherName.contains(query) ||
            subjectName.contains(query) ||
            subjectCode.contains(query) ||
            sectionCode.contains(query) ||
            year.contains(query) ||
            semester.contains(query) ||
            role.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredAssignments: filtered));
    }
  }
}