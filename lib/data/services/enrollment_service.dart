import '../../core/constants/api_constants.dart';
import '../models/entity/enrollment_entity.dart';
import 'api_service.dart';

class EnrollmentService {
  const EnrollmentService._();

  static Future<List<EnrollmentEntity>> getEnrollments({
    String? enrollmentId,
    String? sectionId,
    String? studentId,
  }) async {
    final queryParams = <String, String>{};

    if (sectionId != null && sectionId.isNotEmpty) {
      queryParams['section_id'] = sectionId;
    }
    if (studentId != null && studentId.isNotEmpty) {
      queryParams['student_id'] = studentId;
    }

    final response = await ApiService.getList(
      ApiConstants.enrollments,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    return response
        .map((json) => EnrollmentEntity.fromJson(json))
        .toList(growable: false);
  }

  static Future<EnrollmentEntity> createEnrollment({
    required String enrollmentId,
    required String sectionId,
    required String studentId,
  }) async {
    final response = await ApiService.create(ApiConstants.enrollments, {
      'section_id': sectionId,
      'student_id': studentId,
    });

    return EnrollmentEntity.fromJson(response);
  }

  static Future<void> deleteEnrollment({
    required String enrollmentId,
    required String sectionId,
    required String studentId,
  }) async {
    await ApiService.deleteByPath('${ApiConstants.enrollments}/$enrollmentId');
  }
}

