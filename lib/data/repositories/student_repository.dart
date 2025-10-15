import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentRepository {
  Future<List<StudentModel>> getStudents({
    String? facultyId,
    String? classId,
    String? search,
  }) async {
    try {
      final data = await StudentService.getStudents(
        facultyId: facultyId,
        classId: classId,
        search: search,
      );
      
      return data.map((json) => StudentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<void> createStudent({
    required String code,
    required String fullName,
    required String email,
    String? phone,
    String? classId,
    String? mssv,
    String? password,
  }) async {
    try {
      await StudentService.createStudent(
        code: code,
        fullName: fullName,
        email: email,
        phone: phone,
        classId: classId,
        mssv: mssv,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  Future<void> updateStudent({
    required String id,
    required String code,
    required String fullName,
    required String email,
    String? phone,
    String? classId,
    String? mssv,
  }) async {
    try {
      await StudentService.updateStudent(
        id: id,
        code: code,
        fullName: fullName,
        email: email,
        phone: phone,
        classId: classId,
        mssv: mssv,
      );
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await StudentService.deleteStudent(id);
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}
