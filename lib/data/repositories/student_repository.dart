import '../models/profile.dart';
import '../models/class_model.dart';
import '../models/faculty.dart';
import '../models/attendance.dart';
import '../models/face_embedding.dart';
import '../datasources/supabase_datasource.dart';

abstract class StudentRepository {
  Future<List<Profile>> getStudents();
  Future<Profile> getStudentById(String id);
  Future<Profile> getStudentByCode(String code);
  Future<Profile> createStudent(Profile student);
  Future<Profile> updateStudent(Profile student);
  Future<void> deleteStudent(String id);

  Future<List<ClassModel>> getClasses();
  Future<List<Faculty>> getFaculties();

  Future<List<Attendance>> getAttendanceByStudentId(String studentId);
  Future<Attendance> markAttendance(Attendance attendance);

  Future<FaceEmbedding?> getFaceEmbedding(String studentId);
  Future<FaceEmbedding> saveFaceEmbedding(FaceEmbedding faceEmbedding);
  Future<void> deleteFaceEmbedding(String studentId);
}

class StudentRepositoryImpl implements StudentRepository {
  final SupabaseDataSource _dataSource;

  StudentRepositoryImpl(this._dataSource);

  @override
  Future<List<Profile>> getStudents() async {
    return await _dataSource.getProfiles();
  }

  @override
  Future<Profile> getStudentById(String id) async {
    return await _dataSource.getProfileById(id);
  }

  @override
  Future<Profile> getStudentByCode(String code) async {
    return await _dataSource.getProfileByCode(code);
  }

  @override
  Future<Profile> createStudent(Profile student) async {
    return await _dataSource.createProfile(student);
  }

  @override
  Future<Profile> updateStudent(Profile student) async {
    return await _dataSource.updateProfile(student);
  }

  @override
  Future<void> deleteStudent(String id) async {
    return await _dataSource.deleteProfile(id);
  }

  @override
  Future<List<ClassModel>> getClasses() async {
    return await _dataSource.getClasses();
  }

  @override
  Future<List<Faculty>> getFaculties() async {
    return await _dataSource.getFaculties();
  }

  @override
  Future<List<Attendance>> getAttendanceByStudentId(String studentId) async {
    return await _dataSource.getAttendanceByUserId(studentId);
  }

  @override
  Future<Attendance> markAttendance(Attendance attendance) async {
    return await _dataSource.createAttendance(attendance);
  }

  @override
  Future<FaceEmbedding?> getFaceEmbedding(String studentId) async {
    return await _dataSource.getFaceEmbeddingByUserId(studentId);
  }

  @override
  Future<FaceEmbedding> saveFaceEmbedding(FaceEmbedding faceEmbedding) async {
    return await _dataSource.createOrUpdateFaceEmbedding(faceEmbedding);
  }

  @override
  Future<void> deleteFaceEmbedding(String studentId) async {
    return await _dataSource.deleteFaceEmbedding(studentId);
  }
}
