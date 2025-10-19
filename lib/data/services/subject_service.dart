
import '../../core/constants/api_constants.dart';
import '../models/entity/subject_entity.dart';
import 'api_service.dart';

class SubjectService {
  static Future<List<SubjectEntity>> getSubjects() async {
    final response = await ApiService.getList(ApiConstants.subjects);
    return response.map((json) => SubjectEntity.fromJson(json)).toList();
  }

  static Future<SubjectEntity> createSubject({
    required String code,
    required String name,
    int? credits,
  }) async {
    final response = await ApiService.create(
      ApiConstants.subjects,
      {
        'code': code,
        'name': name,
        'credits': credits,
      },
    );
    return SubjectEntity.fromJson(response);
  }

  static Future<SubjectEntity> updateSubject({
    required String id,
    required String code,
    required String name,
    int? credits,
  }) async {
    final response = await ApiService.update(
      ApiConstants.subjects,
      id,
      {
        'code': code,
        'name': name,
        'credits': credits,
      },
    );
    return SubjectEntity.fromJson(response);
  }

  static Future<void> deleteSubject(String id) async {
    await ApiService.delete(ApiConstants.subjects, id);
  }
}

