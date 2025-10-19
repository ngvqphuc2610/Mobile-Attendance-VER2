import '../../core/constants/api_constants.dart';
import '../models/entity/student_entity.dart';
import '../models/dto/student_dto.dart';
import 'api_service.dart';

class StudentService {
  static Future<List<StudentEntity>> getStudents({
    String? classId,
    String? search,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    
    if (classId != null) queryParams['class_id'] = classId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    
    final response = await ApiService.getList(
      ApiConstants.students,
      queryParams: queryParams,
    );
    
    return response
        .map((json) => StudentEntity.fromJson(json))
        .toList();
  }

  static Future<StudentEntity> getStudentById(String id) async {
    final response = await ApiService.getById(ApiConstants.students, id);
    return StudentEntity.fromJson(response);
  }

  static Future<StudentEntity> createStudent(StudentDto studentDto) async {
    final response = await ApiService.create(
      ApiConstants.students,
      studentDto.toJson(),
    );
    return StudentEntity.fromJson(response);
  }

  static Future<StudentEntity> updateStudent(
    String id,
    StudentDto studentDto,
  ) async {
    final response = await ApiService.update(
      ApiConstants.students,
      id,
      studentDto.toJson(),
    );
    return StudentEntity.fromJson(response);
  }

  static Future<void> deleteStudent(String id) async {
    await ApiService.delete(ApiConstants.students, id);
  }
}

