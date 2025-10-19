
import '../../core/constants/api_constants.dart';
import '../models/entity/class_section_entity.dart';
import 'api_service.dart';

class ClassSectionService {
  static Future<List<ClassSectionEntity>> getClassSections({
    String? classId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (classId != null) queryParams['class_id'] = classId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final response = await ApiService.getList(
      ApiConstants.classSections,
      queryParams: queryParams,
    );
    
    return response
        .map((json) => ClassSectionEntity.fromJson(json))
        .toList();
  }

  static Future<ClassSectionEntity> createClassSectionFromPayload(
      Map<String, dynamic> payload) async {
    final response = await ApiService.create(ApiConstants.classSections, payload);
    return ClassSectionEntity.fromJson(response);
  }

  static Future<ClassSectionEntity> updateClassSectionFromPayload(
      String classSectionId, Map<String, dynamic> payload) async {
    final response = await ApiService.update(
      ApiConstants.classSections,
      classSectionId,
      payload,
    );
    return ClassSectionEntity.fromJson(response);
  }

  static Future<void> deleteClassSection(String id) async {
    await ApiService.delete(ApiConstants.classSections, id);
  }
}

