import '../../core/constants/api_constants.dart';
import '../models/entity/subject_entity.dart';
import '../services/api_service.dart';
import '../services/subject_service.dart';

abstract class SubjectRepository {
  Future<List<SubjectEntity>> getSubjects();
  Future<SubjectEntity> createSubject({
    required String code,
    required String name,
    int? credits,
  });
  Future<SubjectEntity> updateSubject({
    required String id,
    required String code,
    required String name,
    int? credits,
  });
  Future<void> deleteSubject(String id);
}

class SubjectRepositoryImpl implements SubjectRepository {
  @override
  Future<List<SubjectEntity>> getSubjects() async {
    try {
      final response = await ApiService.getList(ApiConstants.subjects);
      return response
          .map((json) => SubjectEntity.fromJson(json))
          .toList(growable: false);
    } catch (e) {
      throw Exception('Failed to fetch subjects: $e');
    }
  }

  @override
  Future<SubjectEntity> createSubject({
    required String code,
    required String name,
    int? credits,
  }) async {
    try {
      final response = await ApiService.create(ApiConstants.subjects, {
        'code': code,
        'name': name,
        'credits': credits,
      });

      final id = response['id']?.toString() ?? '';
      return SubjectEntity(
        id: id,
        code: code,
        name: name,
        credits: credits,
      );
    } catch (e) {
      throw Exception('Failed to create subject: $e');
    }
  }

  @override
  Future<SubjectEntity> updateSubject({
    required String id,
    required String code,
    required String name,
    int? credits,
  }) async {
    try {
      await ApiService.update(ApiConstants.subjects, id, {
        'code': code,
        'name': name,
        'credits': credits,
      });

      return SubjectEntity(
        id: id,
        code: code,
        name: name,
        credits: credits,
      );
    } catch (e) {
      throw Exception('Failed to update subject: $e');
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    try {
      await ApiService.delete(ApiConstants.subjects, id);
    } catch (e) {
      throw Exception('Failed to delete subject: $e');
    }
  }
}
