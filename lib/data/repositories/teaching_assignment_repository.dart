import '../../core/constants/api_constants.dart';
import '../services/api_service.dart';

class TeachingAssignmentRepository {
  
  Future<List<Map<String, dynamic>>> getTeachingAssignments({
    String? sectionId,
    String? teacherId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (sectionId != null && sectionId.isNotEmpty) {
        queryParams['section_id'] = sectionId;
      }
      if (teacherId != null && teacherId.isNotEmpty) {
        queryParams['teacher_id'] = teacherId;
      }

      final response = await ApiService.getList(
        ApiConstants.teachingAssignments,
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      return response
          .map((item) => _normalizeAssignment(item))
          .toList(growable: false);
    } catch (e) {
      throw Exception('Failed to fetch teaching assignments: $e');
    }
  }

  Future<Map<String, dynamic>> createTeachingAssignmentFromPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await ApiService.create(ApiConstants.teachingAssignments, payload);
    } catch (e) {
      throw Exception('Failed to create teaching assignment: $e');
    }
  }

  Future<Map<String, dynamic>> updateTeachingAssignmentFromPayload(
    String compositeId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final ids = _splitCompositeId(compositeId);
      return await ApiService.updateByPath(
        '${ApiConstants.teachingAssignments}/${ids['sectionId']}/${ids['teacherId']}',
        payload,
      );
    } catch (e) {
      throw Exception('Failed to update teaching assignment: $e');
    }
  }

  Future<Map<String, dynamic>> deleteTeachingAssignment(String compositeId) async {
    try {
      final ids = _splitCompositeId(compositeId);
      return await ApiService.deleteByPath(
        '${ApiConstants.teachingAssignments}/${ids['sectionId']}/${ids['teacherId']}',
      );
    } catch (e) {
      throw Exception('Failed to delete teaching assignment: $e');
    }
  }

  Map<String, dynamic> _normalizeAssignment(Map<String, dynamic> item) {
    final map = Map<String, dynamic>.from(item);
    final sectionId = map['section_id']?.toString() ?? '';
    final teacherId = map['teacher_id']?.toString() ?? '';

    map['section_id'] = sectionId;
    map['teacher_id'] = teacherId;
    map['id'] = '$sectionId|$teacherId';

    return map;
  }

  Map<String, String> _splitCompositeId(String compositeId) {
    final parts = compositeId.split('|');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      throw Exception('Invalid teaching assignment identifier');
    }
    return {'sectionId': parts[0], 'teacherId': parts[1]};
  }
}
