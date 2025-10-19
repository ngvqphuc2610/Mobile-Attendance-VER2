
import '../models/entity/class_section_entity.dart';
import '../services/class_section_service.dart';

abstract class ClassSectionRepository {
  Future<List<ClassSectionEntity>> getClassSections({
    String? classId,
    String? search,
  });

  Future<ClassSectionEntity> createClassSectionFromPayload(
      Map<String, dynamic> payload);

  Future<ClassSectionEntity> updateClassSectionFromPayload(
      String classSectionId, Map<String, dynamic> payload);

  Future<void> deleteClassSection(String id);
}

class ClassSectionRepositoryImpl implements ClassSectionRepository {
  @override
  Future<List<ClassSectionEntity>> getClassSections({
    String? classId,
    String? search,
  }) async {
    return await ClassSectionService.getClassSections(
      classId: classId,
      search: search,
    );
  }

  @override
  Future<ClassSectionEntity> createClassSectionFromPayload(
      Map<String, dynamic> payload) async {
    return await ClassSectionService.createClassSectionFromPayload(payload);
  }

  @override
  Future<ClassSectionEntity> updateClassSectionFromPayload(
      String classSectionId, Map<String, dynamic> payload) async {
    return await ClassSectionService.updateClassSectionFromPayload(
      classSectionId,
      payload,
    );
  }

  @override
  Future<void> deleteClassSection(String id) async {
    await ClassSectionService.deleteClassSection(id);
  }
}