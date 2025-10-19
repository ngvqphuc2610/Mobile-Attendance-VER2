import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/subject_repository.dart';
import 'subject_event.dart';
import 'subject_state.dart';

class SubjectBloc extends Bloc<SubjectEvent, SubjectState> {
  final SubjectRepository _repository;

  SubjectBloc({required SubjectRepository repository})
      : _repository = repository,
        super(SubjectInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<CreateSubject>(_onCreateSubject);
    on<UpdateSubject>(_onUpdateSubject);
    on<DeleteSubject>(_onDeleteSubject);
    on<FilterSubjects>(_onFilterSubjects);
  }

  Future<void> _onLoadSubjects(
    LoadSubjects event,
    Emitter<SubjectState> emit,
  ) async {
    emit(SubjectLoading());

    try {
      final subjects = await _repository.getSubjects();
      emit(SubjectsLoaded(
        subjects: subjects,
        filteredSubjects: subjects,
      ));
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  Future<void> _onCreateSubject(
    CreateSubject event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await _repository.createSubject(
        code: event.code,
        name: event.name,
        credits: event.credits,
      );
      emit(const SubjectOperationSuccess('Thêm môn học thành công'));
      add(const LoadSubjects());
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  Future<void> _onUpdateSubject(
    UpdateSubject event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await _repository.updateSubject(
        id: event.id,
        code: event.code,
        name: event.name,
        credits: event.credits,
      );
      emit(const SubjectOperationSuccess('Cập nhật môn học thành công'));
      add(const LoadSubjects());
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  Future<void> _onDeleteSubject(
    DeleteSubject event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await _repository.deleteSubject(event.id);
      emit(const SubjectOperationSuccess('Xóa môn học thành công'));
      add(const LoadSubjects());
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  void _onFilterSubjects(
    FilterSubjects event,
    Emitter<SubjectState> emit,
  ) {
    final currentState = state;
    if (currentState is SubjectsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(filteredSubjects: currentState.subjects));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.subjects.where((subject) {
        return subject.name.toLowerCase().contains(query) ||
               subject.code.toLowerCase().contains(query);
      }).toList();

      emit(currentState.copyWith(filteredSubjects: filtered));
    }
  }
}