import '../../core/constants/api_constants.dart';
import '../models/entity/class_entity.dart';
import 'api_service.dart';

class ClassService {
  static Future<List<ClassEntity>> getClasses({
    String? facultyId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (facultyId != null) queryParams['faculty_id'] = facultyId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final response = await ApiService.getList(
      ApiConstants.classes,
      queryParams: queryParams,
    );
    
    return response.map((json) => ClassEntity.fromJson(json)).toList();
  }

  static Future<ClassEntity> getClassById(String id) async {
    final response = await ApiService.getById(ApiConstants.classes, id);
    return ClassEntity.fromJson(response);
  }

  static Future<ClassEntity> createClass({
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  }) async {
    final response = await ApiService.create(
      ApiConstants.classes,
      {
        'code': code,
        'name': name,
        if (facultyId != null) 'faculty_id': facultyId,
        if (cohortId != null) 'cohort_id': cohortId,
      },
    );
    return ClassEntity.fromJson(response);
  }

  static Future<ClassEntity> updateClass({
    required String id,
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  }) async {
    final response = await ApiService.update(
      ApiConstants.classes,
      id,
      {
        'code': code,
        'name': name,
        if (facultyId != null) 'faculty_id': facultyId,
        if (cohortId != null) 'cohort_id': cohortId,
      },
    );
    return ClassEntity.fromJson(response);
  }

  static Future<void> deleteClass(String id) async {
    await ApiService.delete(ApiConstants.classes, id);
  }

  static Future<Map<String, dynamic>> createClassFromPayload(
    Map<String, dynamic> payload,
  ) {
    return ApiService.create(ApiConstants.classes, payload);
  }

  static Future<Map<String, dynamic>> updateClassFromPayload(
    String id,
    Map<String, dynamic> payload,
  ) {
    return ApiService.update(ApiConstants.classes, id, payload);
  }
  
}
