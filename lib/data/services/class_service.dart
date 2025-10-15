import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class ClassService {
  static Future<List<Map<String, dynamic>>> getClasses({
    String? facultyId,
  }) async {
    final queryParams = <String, String>{};
    
    if (facultyId != null) queryParams['faculty_id'] = facultyId;
    
    return await ApiService.getList(ApiConstants.classes, queryParams: queryParams);
  }
  
  static Future<Map<String, dynamic>> createClass({
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  }) async {
    return await ApiService.create(ApiConstants.classes, {
      'code': code,
      'name': name,
      'faculty_id': facultyId,
      'cohort_id': cohortId,
    });
  }
  
  static Future<Map<String, dynamic>> updateClass({
    required String id,
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  }) async {
    return await ApiService.update(ApiConstants.classes, id, {
      'code': code,
      'name': name,
      'faculty_id': facultyId,
      'cohort_id': cohortId,
    });
  }
  
  static Future<Map<String, dynamic>> deleteClass(String id) async {
    return await ApiService.delete(ApiConstants.classes, id);
  }
}