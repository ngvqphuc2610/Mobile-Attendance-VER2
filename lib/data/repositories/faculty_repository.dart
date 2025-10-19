import '../models/entity/faculty_entity.dart';
import '../services/faculty_service.dart';

abstract class FacultyRepository {
  Future<List<FacultyEntity>> getFaculties();
  Future<FacultyEntity> createFaculty({
    required String code,
    required String name,
  });
  Future<FacultyEntity> updateFaculty({
    required String id,
    required String code,
    required String name,
  });
  Future<void> deleteFaculty(String id);
}

class FacultyRepositoryImpl implements FacultyRepository {
  @override
  Future<List<FacultyEntity>> getFaculties() async {
    try {
      return await FacultyService.getFaculties();
    } catch (e) {
      throw Exception('Failed to fetch faculties: $e');
    }
  }

  @override
  Future<FacultyEntity> createFaculty({
    required String code,
    required String name,
  }) async {
    try {
      return await FacultyService.createFaculty(
        code: code,
        name: name,
      );
    } catch (e) {
      throw Exception('Failed to create faculty: $e');
    }
  }

  @override
  Future<FacultyEntity> updateFaculty({
    required String id,
    required String code,
    required String name,
  }) async {
    try {
      return await FacultyService.updateFaculty(
        id: id,
        code: code,
        name: name,
      );
    } catch (e) {
      throw Exception('Failed to update faculty: $e');
    }
  }

  @override
  Future<void> deleteFaculty(String id) async {
    try {
      await FacultyService.deleteFaculty(id);
    } catch (e) {
      throw Exception('Failed to delete faculty: $e');
    }
  }
}