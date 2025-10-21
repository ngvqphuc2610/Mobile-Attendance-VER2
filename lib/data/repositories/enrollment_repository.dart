import '../models/entity/enrollment_entity.dart';
import '../services/enrollment_service.dart';

abstract class EnrollmentRepository {
  Future<List<EnrollmentEntity>> getEnrollments({
    String? sectionId,
    String? studentId,
  });

  Future<EnrollmentEntity> createEnrollment({
    required String sectionId,
    required String studentId,
  });

  Future<void> deleteEnrollment({
    required String sectionId,
    required String studentId,
  });
}

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  const EnrollmentRepositoryImpl();

  @override
  Future<List<EnrollmentEntity>> getEnrollments({
    String? sectionId,
    String? studentId,
  }) async {
    try {
      return await EnrollmentService.getEnrollments(
        sectionId: sectionId,
        studentId: studentId,
      );
    } catch (e) {
      throw Exception('Failed to fetch enrollments: $e');
    }
  }

  @override
  Future<EnrollmentEntity> createEnrollment({
    required String sectionId,
    required String studentId,
  }) async {
    try {
      return await EnrollmentService.createEnrollment(
        sectionId: sectionId,
        studentId: studentId,
      );
    } catch (e) {
      throw Exception('Failed to create enrollment: $e');
    }
  }

  @override
  Future<void> deleteEnrollment({
    required String sectionId,
    required String studentId,
  }) async {
    try {
      await EnrollmentService.deleteEnrollment(
        sectionId: sectionId,
        studentId: studentId,
      );
    } catch (e) {
      throw Exception('Failed to delete enrollment: $e');
    }
  }
}
