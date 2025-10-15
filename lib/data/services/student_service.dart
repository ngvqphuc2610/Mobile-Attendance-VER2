import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class StudentService {
  static Future<List<Map<String, dynamic>>> getStudents({
    String? facultyId,
    String? classId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (facultyId != null) queryParams['faculty_id'] = facultyId;
    if (classId != null) queryParams['class_id'] = classId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    return await ApiService.getList(ApiConstants.students, queryParams: queryParams);
  }
  
  static Future<Map<String, dynamic>> createStudent({
    required String code,
    required String fullName,
    required String email,
    String? phone,
    String? classId,
    String? mssv,
    String? password,
  }) async {
    return await ApiService.create(ApiConstants.students, {
      'code': code,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'class_id': classId,
      'mssv': mssv,
      'password': password ?? '123456',
    });
  }
  
  static Future<Map<String, dynamic>> updateStudent({
    required String id,
    required String code,
    required String fullName,
    required String email,
    String? phone,
    String? classId,
    String? mssv,
  }) async {
    return await ApiService.update(ApiConstants.students, id, {
      'code': code,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'class_id': classId,
      'mssv': mssv,
    });
  }
  
  static Future<Map<String, dynamic>> deleteStudent(String id) async {
    return await ApiService.delete(ApiConstants.students, id);
  }
}