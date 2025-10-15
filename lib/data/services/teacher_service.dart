import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class TeacherService {
  static Future<List<Map<String, dynamic>>> getTeachers({
    String? facultyId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (facultyId != null) queryParams['faculty_id'] = facultyId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    return await ApiService.getList(ApiConstants.teachers, queryParams: queryParams);
  }
  
  static Future<Map<String, dynamic>> createTeacher({
    required String code,
    required String fullName,
    required String email,
    String? phone,
    String? facultyId,
    String? title,
    String? office,
    String? password,
  }) async {
    return await ApiService.create(ApiConstants.teachers, {
      'code': code,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'faculty_id': facultyId,
      'title': title,
      'office': office,
      'password': password ?? '123456',
    });
  }
  
  static Future<Map<String, dynamic>> updateTeacher({
    required String id,
    required String code,
    required String fullName,
    required String email,
    String? phone,
    String? facultyId,
    String? title,
    String? office,
  }) async {
    return await ApiService.update(ApiConstants.teachers, id, {
      'code': code,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'faculty_id': facultyId,
      'title': title,
      'office': office,
    });
  }
  
  static Future<Map<String, dynamic>> deleteTeacher(String id) async {
    return await ApiService.delete(ApiConstants.teachers, id);
  }
}
