import '../../core/constants/api_constants.dart';
import '../models/teaching_assignment_model.dart';
import 'api_service.dart';

class TeachingAssignmentService {
  static Future<List<TeachingAssignmentModel>> getTeachingAssignments({
    String? sectionId,
    String? teacherId,
    String? role,
  }) async {
    final queryParams = <String, String>{};
    
    if (sectionId != null) queryParams['section_id'] = sectionId;
    if (teacherId != null) queryParams['teacher_id'] = teacherId;
    if (role != null) queryParams['role'] = role;
    
    final response = await ApiService.getList(
      ApiConstants.teachingAssignments,
      queryParams: queryParams,
    );
    
    return response
        .map((json) => TeachingAssignmentModel.fromJson(json))
        .toList();
  }

  static Future<TeachingAssignmentModel> createTeachingAssignment({
    required String sectionId,
    required String teacherId,
    required String role,
  }) async {
    final response = await ApiService.create(
      ApiConstants.teachingAssignments,
      {
        'section_id': sectionId,
        'teacher_id': teacherId,
        'role': role,
      },
    );
    
    return TeachingAssignmentModel.fromJson(response);
  }

  static Future<TeachingAssignmentModel> updateTeachingAssignment({
    required String originalSectionId,
    required String originalTeacherId,
    required String sectionId,
    required String teacherId,
    required String role,
  }) async {
    final response = await ApiService.update(
      ApiConstants.teachingAssignments,
      '$originalSectionId|$originalTeacherId',
      {
        'section_id': sectionId,
        'teacher_id': teacherId,
        'role': role,
      },
    );
    
    return TeachingAssignmentModel.fromJson(response);
  }

  static Future<void> deleteTeachingAssignment({
    required String sectionId,
    required String teacherId,
  }) async {
    await ApiService.delete(
      '${ApiConstants.teachingAssignments}/$sectionId/$teacherId',
      '$sectionId|$teacherId',
    );
  }
}

