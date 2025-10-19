import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/class_section_repository.dart';
import 'class_section_event.dart';
import 'class_section_state.dart';

class ClassSectionBloc extends Bloc<ClassSectionEvent, ClassSectionState> {
  final ClassSectionRepository _repository;

  ClassSectionBloc({required ClassSectionRepository classSectionRepository})
    : _repository = classSectionRepository,
      super(ClassSectionInitial()) {
    on<LoadClassSections>(_onLoadClassSections);
    on<CreateClassSection>(_onCreateClassSection);
    on<UpdateClassSection>(_onUpdateClassSection);
    on<DeleteClassSection>(_onDeleteClassSection);
    on<FilterClassSections>(_onFilterClassSections);
  }

  Future<void> _onLoadClassSections(
    LoadClassSections event,
    Emitter<ClassSectionState> emit,
  ) async {
    emit(ClassSectionLoading());

    try {
      final sections = await _repository.getClassSections(
        classId: event.classId,
      );
      emit(ClassSectionsLoaded(sections: sections, filteredSections: sections));
    } catch (e) {
      emit(ClassSectionError(e.toString()));
    }
  }

  Future<void> _onCreateClassSection(
    CreateClassSection event,
    Emitter<ClassSectionState> emit,
  ) async {
    try {
      await _repository.createClassSectionFromPayload(event.payload);
      emit(const ClassSectionOperationSuccess('Tạo học phần thành công'));
      add(const LoadClassSections());
    } catch (e) {
      emit(ClassSectionError(e.toString()));
    }
  }

  Future<void> _onUpdateClassSection(
    UpdateClassSection event,
    Emitter<ClassSectionState> emit,
  ) async {
    try {
      await _repository.updateClassSectionFromPayload(
        event.sectionId,
        event.payload,
      );
      emit(const ClassSectionOperationSuccess('Cập nhật học phần thành công'));
      add(const LoadClassSections());
    } catch (e) {
      emit(ClassSectionError(e.toString()));
    }
  }

  Future<void> _onDeleteClassSection(
    DeleteClassSection event,
    Emitter<ClassSectionState> emit,
  ) async {
    try {
      await _repository.deleteClassSection(event.id);
      emit(const ClassSectionOperationSuccess('Xóa học phần thành công'));
      add(const LoadClassSections());
    } catch (e) {
      emit(ClassSectionError(e.toString()));
    }
  }

  void _onFilterClassSections(
    FilterClassSections event,
    Emitter<ClassSectionState> emit,
  ) {
    final currentState = state;
    if (currentState is ClassSectionsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(filteredSections: currentState.sections));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.sections
          .where((section) {
            final subjectName = section.subject?.name?.toLowerCase() ?? '';
            final subjectCode = section.subject?.code?.toLowerCase() ?? '';
            final sectionCode = section.sectionCode.toLowerCase();
            final year = section.year.toString();
            final semester = section.semester.toString();
            return subjectName.contains(query) ||
                subjectCode.contains(query) ||
                sectionCode.contains(query) ||
                year.contains(query) ||
                semester.contains(query);
          })
          .toList(growable: false);

      emit(currentState.copyWith(filteredSections: filtered));
    }
  }
}
