import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/student_repository.dart';

// Events
abstract class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class StudentLoadRequested extends StudentEvent {
  final String? facultyId;
  final String? classId;
  final String? search;

  const StudentLoadRequested({
    this.facultyId,
    this.classId,
    this.search,
  });

  @override
  List<Object?> get props => [facultyId, classId, search];
}

class StudentCreateRequested extends StudentEvent {
  final String code;
  final String fullName;
  final String email;
  final String? phone;
  final String? classId;
  final String? mssv;
  final String? password;

  const StudentCreateRequested({
    required this.code,
    required this.fullName,
    required this.email,
    this.phone,
    this.classId,
    this.mssv,
    this.password,
  });

  @override
  List<Object?> get props => [code, fullName, email, phone, classId, mssv, password];
}

class StudentUpdateRequested extends StudentEvent {
  final String id;
  final String code;
  final String fullName;
  final String email;
  final String? phone;
  final String? classId;
  final String? mssv;

  const StudentUpdateRequested({
    required this.id,
    required this.code,
    required this.fullName,
    required this.email,
    this.phone,
    this.classId,
    this.mssv,
  });

  @override
  List<Object?> get props => [id, code, fullName, email, phone, classId, mssv];
}

class StudentDeleteRequested extends StudentEvent {
  final String id;

  const StudentDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

// States
abstract class StudentState extends Equatable {
  const StudentState();

  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {}

class StudentLoading extends StudentState {}

class StudentLoaded extends StudentState {
  final List<StudentModel> students;

  const StudentLoaded({required this.students});

  @override
  List<Object?> get props => [students];
}

class StudentOperationSuccess extends StudentState {
  final String message;

  const StudentOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class StudentError extends StudentState {
  final String message;

  const StudentError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentRepository _studentRepository;

  StudentBloc({required StudentRepository studentRepository})
      : _studentRepository = studentRepository,
        super(StudentInitial()) {
    on<StudentLoadRequested>(_onLoadRequested);
    on<StudentCreateRequested>(_onCreateRequested);
    on<StudentUpdateRequested>(_onUpdateRequested);
    on<StudentDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    StudentLoadRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    
    try {
      final students = await _studentRepository.getStudents(
        facultyId: event.facultyId,
        classId: event.classId,
        search: event.search,
      );
      emit(StudentLoaded(students: students));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    StudentCreateRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    
    try {
      await _studentRepository.createStudent(
        code: event.code,
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        classId: event.classId,
        mssv: event.mssv,
        password: event.password,
      );
      emit(const StudentOperationSuccess(message: 'Student created successfully'));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    StudentUpdateRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    
    try {
      await _studentRepository.updateStudent(
        id: event.id,
        code: event.code,
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        classId: event.classId,
        mssv: event.mssv,
      );
      emit(const StudentOperationSuccess(message: 'Student updated successfully'));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    StudentDeleteRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    
    try {
      await _studentRepository.deleteStudent(event.id);
      emit(const StudentOperationSuccess(message: 'Student deleted successfully'));
    } catch (e) {
      emit(StudentError(message: e.toString()));
    }
  }
}
