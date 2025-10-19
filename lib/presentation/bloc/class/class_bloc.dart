
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/class_repository.dart';

import 'class_event.dart';
import 'class_state.dart';

class ClassBloc extends Bloc<ClassEvent, ClassState> {
  final ClassRepository _repository;
  

  ClassBloc({
    required ClassRepository classRepository,
    
  })  : _repository = classRepository,
        super(ClassInitial()) {
    on<LoadClasses>(_onLoadClasses);
    on<CreateClass>(_onCreateClass);
    on<UpdateClass>(_onUpdateClass);
    on<DeleteClass>(_onDeleteClass);
    on<FilterClasses>(_onFilterClasses);
  }

  Future<void> _onLoadClasses(
    LoadClasses event,
    Emitter<ClassState> emit,
  ) async {
    emit(ClassLoading());

    try {
      final classes = await _repository.getClasses(
        facultyId: event.facultyId,
        search: event.search,
      );

      emit(ClassesLoaded(
        classes: classes,
        filteredClasses: classes,
      ));
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onCreateClass(
    CreateClass event,
    Emitter<ClassState> emit,
  ) async {
    try {
      await _repository.createClass(
        code: event.code,
        name: event.name,
        facultyId: event.facultyId,
        cohortId: event.cohortId,
      );
      
      emit(const ClassOperationSuccess('Tạo lớp thành công'));
      add(const LoadClasses());
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onUpdateClass(
    UpdateClass event,
    Emitter<ClassState> emit,
  ) async {
    try {
      await _repository.updateClass(
        id: event.id,
        code: event.code,
        name: event.name,
        facultyId: event.facultyId,
        cohortId: event.cohortId,
      );
      emit(const ClassOperationSuccess('Cập nhật lớp thành công'));
      add(const LoadClasses());
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onDeleteClass(
    DeleteClass event,
    Emitter<ClassState> emit,
  ) async {
    try {
      await _repository.deleteClass(event.id);
      emit(const ClassOperationSuccess('Xóa lớp thành công'));
      add(const LoadClasses());
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onFilterClasses(
    FilterClasses event,
    Emitter<ClassState> emit,
  ) async {
    if (state is ClassesLoaded) {
      final currentState = state as ClassesLoaded;
      final filteredClasses = currentState.classes.where((cls) {
        final searchLower = event.query.toLowerCase();
        return cls.name.toLowerCase().contains(searchLower) ||
            cls.code.toLowerCase().contains(searchLower);
      }).toList();

      emit(ClassesLoaded(
        classes: currentState.classes,
        filteredClasses: filteredClasses,
      ));
    }
  }
}
