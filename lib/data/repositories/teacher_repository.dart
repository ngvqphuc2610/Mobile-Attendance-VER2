import '../models/entity/teacher_entity.dart';
import '../models/dto/teacher_dto.dart';
import '../services/teacher_service.dart';

abstract class TeacherRepository {
  Future<List<TeacherEntity>> getTeachers({String? facultyId, String? search});
  Future<TeacherEntity> getTeacherById(String id);
  Future<TeacherEntity> createTeacher(TeacherDto teacherDto);
  Future<TeacherEntity> updateTeacher(String id, TeacherDto teacherDto);
  Future<void> deleteTeacher(String id);
}

class TeacherRepositoryImpl implements TeacherRepository {
  @override
  Future<List<TeacherEntity>> getTeachers({String? facultyId, String? search}) async {
    try {
      return await TeacherService.getTeachers(facultyId: facultyId, search: search);
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  @override
  Future<TeacherEntity> getTeacherById(String id) async {
    try {
      return await TeacherService.getTeacherById(id);
    } catch (e) {
      throw Exception('Failed to fetch teacher: $e');
    }
  }

  @override
  Future<TeacherEntity> createTeacher(TeacherDto teacherDto) async {
    try {
      return await TeacherService.createTeacher(teacherDto);
    } catch (e) {
      throw Exception('Failed to create teacher: $e');
    }
  }

  @override
  Future<TeacherEntity> updateTeacher(String id, TeacherDto teacherDto) async {
    try {
      return await TeacherService.updateTeacher(id, teacherDto);
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  @override
  Future<void> deleteTeacher(String id) async {
    try {
      await TeacherService.deleteTeacher(id);
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }
}