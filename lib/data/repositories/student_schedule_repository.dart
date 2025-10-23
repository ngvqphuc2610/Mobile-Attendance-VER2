
import '../models/entity/student_schedule_entity.dart';
import '../services/student_schedule_service.dart';

class StudentScheduleRepository {
  Future<List<StudentScheduleEntity>> getStudentSchedules({
    required String studentId,
    DateTime? from,
    DateTime? to,
    int? semester,
    int? year,
  }) async {
    return StudentScheduleService.fetchStudentSchedules(
      studentId: studentId,
      from: from,
      to: to,
      semester: semester,
      year: year,
    );
  }

  Future<StudentScheduleEntity> getStudentScheduleById({
    required String studentId,
    required String id,
  }) async {
    final schedules =
        await getStudentSchedules(studentId: studentId);
    return schedules.firstWhere((s) => s.id == id);
  }

  Future<List<StudentScheduleEntity>> getStudentSchedulesBySemesterAndYear({
    required String studentId,
    required int semester,
    required int year,
  }) async {
    final schedules = await getStudentSchedules(studentId: studentId);
    return schedules
        .where((s) => s.semester == semester && s.year == year)
        .toList(growable: false);
  }
}


