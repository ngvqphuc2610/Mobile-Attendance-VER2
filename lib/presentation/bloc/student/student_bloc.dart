import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/student_repository.dart';
import 'student_event.dart';
import 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentRepository _repository;

  StudentBloc({
    required StudentRepository repository,
  }) : _repository = repository, super(StudentInitial()) {
    on<LoadStudents>(_onLoadStudents);
    on<LoadStudentById>(_onLoadStudentById);
    on<CreateStudent>(_onCreateStudent);
    on<UpdateStudent>(_onUpdateStudent);
    on<DeleteStudent>(_onDeleteStudent);
    on<FilterStudents>(_onFilterStudents);
  }

  Future<void> _onLoadStudents(
    LoadStudents event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    
    try {
      final students = await _repository.getStudents(
        classId: event.classId,
        search: event.search,
        page: event.page,
        limit: event.limit,
      );
      
      emit(StudentsLoaded(
        students: students,
        filteredStudents: students,
      ));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _onLoadStudentById(
    LoadStudentById event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    
    try {
      final student = await _repository.getStudentById(event.id);
      emit(StudentLoaded(student));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _onCreateStudent(
    CreateStudent event,
    Emitter<StudentState> emit,
  ) async {
    try {
      await _repository.createStudent(event.studentDto);
      emit(const StudentOperationSuccess('Tạo sinh viên thành công'));
      
      // Reload students
      add(const LoadStudents());
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _onUpdateStudent(
    UpdateStudent event,
    Emitter<StudentState> emit,
  ) async {
    try {
      await _repository.updateStudent(event.id, event.studentDto);
      emit(const StudentOperationSuccess('Cập nhật sinh viên thành công'));
      
      // Reload students
      add(const LoadStudents());
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _onDeleteStudent(
    DeleteStudent event,
    Emitter<StudentState> emit,
  ) async {
    try {
      await _repository.deleteStudent(event.id);
      emit(const StudentOperationSuccess('Xóa sinh viên thành công'));
      
      // Reload students
      add(const LoadStudents());
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  void _onFilterStudents(
    FilterStudents event,
    Emitter<StudentState> emit,
  ) {
    final currentState = state;
    if (currentState is StudentsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(
          filteredStudents: currentState.students,
        ));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.students.where((student) {
        final profile = student.profile;
        return student.mssv?.toLowerCase().contains(query) == true ||
               profile?.fullName.toLowerCase().contains(query) == true ||
               profile?.code.toLowerCase().contains(query) == true ||
               profile?.email?.toLowerCase().contains(query) == true;
      }).toList();

      emit(currentState.copyWith(filteredStudents: filtered));
    }
  }
}
