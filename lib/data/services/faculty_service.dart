import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class FacultyService {
  static Future<List<Map<String, dynamic>>> getFaculties() async {
    return await ApiService.getList(ApiConstants.faculties);
  }
  
  static Future<Map<String, dynamic>> createFaculty({
    required String code,
    required String name,
  }) async {
    return await ApiService.create(ApiConstants.faculties, {
      'code': code,
      'name': name,
    });
  }
  
  static Future<Map<String, dynamic>> updateFaculty({
    required String id,
    required String code,
    required String name,
  }) async {
    return await ApiService.update(ApiConstants.faculties, id, {
      'code': code,
      'name': name,
    });
  }
  
  static Future<Map<String, dynamic>> deleteFaculty(String id) async {
    return await ApiService.delete(ApiConstants.faculties, id);
  }
}