import '../../core/constants/api_constants.dart';
import '../models/entity/teacher_entity.dart';
import '../models/dto/teacher_dto.dart';
import 'api_service.dart';

class TeacherService {
  static Future<List<TeacherEntity>> getTeachers({
    String? facultyId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (facultyId != null) queryParams['faculty_id'] = facultyId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final response = await ApiService.getList(
      ApiConstants.teachers,
      queryParams: queryParams,
    );
    
    return response.map((json) => TeacherEntity.fromJson(json)).toList();
  }

  static Future<TeacherEntity> getTeacherById(String id) async {
    final response = await ApiService.getById(ApiConstants.teachers, id);
    return TeacherEntity.fromJson(response);
  }

  static Future<TeacherEntity> createTeacher(TeacherDto teacherDto) async {
    final response = await ApiService.create(
      ApiConstants.teachers,
      teacherDto.toJson(),
    );
    return TeacherEntity.fromJson(response);
  }

  static Future<TeacherEntity> updateTeacher(String id, TeacherDto teacherDto) async {
    final response = await ApiService.update(
      ApiConstants.teachers,
      id,
      teacherDto.toJson(),
    );
    return TeacherEntity.fromJson(response);
  }

  static Future<void> deleteTeacher(String id) async {
    await ApiService.delete(ApiConstants.teachers, id);
  }
}

