import '../models/entity/class_entity.dart';
import '../services/class_service.dart';

abstract class ClassRepository {
  Future<List<ClassEntity>> getClasses({
    String? facultyId,
    String? search,
  });

  Future<ClassEntity> createClass({
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  });

  Future<ClassEntity> updateClass({
    required String id,
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  });

  Future<void> deleteClass(String id);
}

class ClassRepositoryImpl implements ClassRepository {
  @override
  Future<List<ClassEntity>> getClasses({
    String? facultyId,
    String? search,
  }) async {
    try {
      // Nếu ClassService trả List<Map> thì sửa thành:
      // final raw = await ClassService.getClasses(...);
      // return raw.map((e) => ClassEntity.fromJson(e)).toList();
      return await ClassService.getClasses(
        facultyId: facultyId,
        search: search,
      );
    } catch (e) {
      throw Exception('Failed to fetch classes: $e');
    }
  }

  @override
  Future<ClassEntity> createClass({
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  }) async {
    try {
      // Nếu service trả Map, map sang ClassEntity.fromJson(json)
      return await ClassService.createClass(
        code: code,
        name: name,
        facultyId: facultyId,
        cohortId: cohortId,
      );
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  @override
  Future<ClassEntity> updateClass({
    required String id,
    required String code,
    required String name,
    String? facultyId,
    String? cohortId,
  }) async {
    try {
      return await ClassService.updateClass(
        id: id,
        code: code,
        name: name,
        facultyId: facultyId,
        cohortId: cohortId,
      );
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  @override
  Future<void> deleteClass(String id) async {
    try {
      await ClassService.deleteClass(id);
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }
}
