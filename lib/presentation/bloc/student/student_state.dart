import 'package:equatable/equatable.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/faculty.dart';

enum StudentStatus { initial, loading, loaded, error }

class StudentState extends Equatable {
  final StudentStatus status;
  final List<Profile> students;
  final List<Profile> filteredStudents;
  final List<ClassModel> classes;
  final List<Faculty> faculties;
  final Profile? selectedStudent;
  final String? errorMessage;
  final String searchQuery;

  const StudentState({
    this.status = StudentStatus.initial,
    this.students = const [],
    this.filteredStudents = const [],
    this.classes = const [],
    this.faculties = const [],
    this.selectedStudent,
    this.errorMessage,
    this.searchQuery = '',
  });

  StudentState copyWith({
    StudentStatus? status,
    List<Profile>? students,
    List<Profile>? filteredStudents,
    List<ClassModel>? classes,
    List<Faculty>? faculties,
    Profile? selectedStudent,
    String? errorMessage,
    String? searchQuery,
  }) {
    return StudentState(
      status: status ?? this.status,
      students: students ?? this.students,
      filteredStudents: filteredStudents ?? this.filteredStudents,
      classes: classes ?? this.classes,
      faculties: faculties ?? this.faculties,
      selectedStudent: selectedStudent ?? this.selectedStudent,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    status,
    students,
    filteredStudents,
    classes,
    faculties,
    selectedStudent,
    errorMessage,
    searchQuery,
  ];
}
