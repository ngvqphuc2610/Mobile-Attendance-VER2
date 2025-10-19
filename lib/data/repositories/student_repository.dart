import '../models/entity/student_entity.dart';
import '../models/dto/student_dto.dart';
import '../services/student_service.dart';

abstract class StudentRepository {
  Future<List<StudentEntity>> getStudents({
    String? classId,
    String? search,
    int? page,
    int? limit,
  });
  
  Future<StudentEntity> getStudentById(String id);
  Future<StudentEntity> createStudent(StudentDto studentDto);
  Future<StudentEntity> updateStudent(String id, StudentDto studentDto);
  Future<void> deleteStudent(String id);
}

class StudentRepositoryImpl implements StudentRepository {
  @override
  Future<List<StudentEntity>> getStudents({
    String? classId,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      return await StudentService.getStudents(
        classId: classId,
        search: search,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  @override
  Future<StudentEntity> getStudentById(String id) async {
    try {
      return await StudentService.getStudentById(id);
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }

  @override
  Future<StudentEntity> createStudent(StudentDto studentDto) async {
    try {
      return await StudentService.createStudent(studentDto);
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  @override
  Future<StudentEntity> updateStudent(String id, StudentDto studentDto) async {
    try {
      return await StudentService.updateStudent(id, studentDto);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  @override
  Future<void> deleteStudent(String id) async {
    try {
      await StudentService.deleteStudent(id);
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}
