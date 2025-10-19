import '../../core/constants/api_constants.dart';
import '../models/entity/faculty_entity.dart';
import 'api_service.dart';

class FacultyService {
  static Future<List<FacultyEntity>> getFaculties({
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    final response = await ApiService.getList(
      ApiConstants.faculties,
      queryParams: queryParams,
    );
    
    return response
        .map((json) => FacultyEntity.fromJson(json))
        .toList();
  }

  static Future<FacultyEntity> getFacultyById(String id) async {
    final response = await ApiService.getById(ApiConstants.faculties, id);
    return FacultyEntity.fromJson(response);
  }

  static Future<FacultyEntity> createFaculty({
    required String code,
    required String name,
  }) async {
    final response = await ApiService.create(
      ApiConstants.faculties,
      {
        'code': code,
        'name': name,
      },
    );
    return FacultyEntity.fromJson(response);
  }

  static Future<FacultyEntity> updateFaculty({
    required String id,
    required String code,
    required String name,
  }) async {
    final response = await ApiService.update(
      ApiConstants.faculties,
      id,
      {
        'code': code,
        'name': name,
      },
    );
    return FacultyEntity.fromJson(response);
  }

  static Future<void> deleteFaculty(String id) async {
    await ApiService.delete(ApiConstants.faculties, id);
  }
}

