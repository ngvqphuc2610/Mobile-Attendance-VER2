import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/class_model.dart';
import '../models/faculty.dart';
import '../models/attendance.dart';
import '../models/face_embedding.dart';

abstract class SupabaseDataSource {
  // Profile methods
  Future<List<Profile>> getProfiles();
  Future<Profile> getProfileById(String id);
  Future<Profile> getProfileByCode(String code);
  Future<Profile> createProfile(Profile profile);
  Future<Profile> updateProfile(Profile profile);
  Future<void> deleteProfile(String id);

  // Class methods
  Future<List<ClassModel>> getClasses();
  Future<ClassModel> getClassById(String id);
  Future<ClassModel> createClass(ClassModel classModel);
  Future<ClassModel> updateClass(ClassModel classModel);
  Future<void> deleteClass(String id);

  // Faculty methods
  Future<List<Faculty>> getFaculties();
  Future<Faculty> getFacultyById(String id);
  Future<Faculty> createFaculty(Faculty faculty);
  Future<Faculty> updateFaculty(Faculty faculty);
  Future<void> deleteFaculty(String id);

  // Attendance methods
  Future<List<Attendance>> getAttendance();
  Future<List<Attendance>> getAttendanceByUserId(String userId);
  Future<Attendance> createAttendance(Attendance attendance);
  Future<void> deleteAttendance(int id);

  // Face embedding methods
  Future<FaceEmbedding?> getFaceEmbeddingByUserId(String userId);
  Future<FaceEmbedding> createOrUpdateFaceEmbedding(
    FaceEmbedding faceEmbedding,
  );
  Future<void> deleteFaceEmbedding(String userId);
}

class SupabaseDataSourceImpl implements SupabaseDataSource {
  final SupabaseClient _client;

  SupabaseDataSourceImpl(this._client);

  @override
  Future<List<Profile>> getProfiles() async {
    final response = await _client.from('profiles').select().order('full_name');

    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  @override
  Future<Profile> getProfileById(String id) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return Profile.fromJson(response);
  }

  @override
  Future<Profile> getProfileByCode(String code) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('code', code)
        .single();

    return Profile.fromJson(response);
  }

  @override
  Future<Profile> createProfile(Profile profile) async {
    final response = await _client
        .from('profiles')
        .insert(profile.toJson())
        .select()
        .single();

    return Profile.fromJson(response);
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final response = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();

    return Profile.fromJson(response);
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _client.from('profiles').delete().eq('id', id);
  }

  @override
  Future<List<ClassModel>> getClasses() async {
    final response = await _client.from('classes').select().order('name');

    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  @override
  Future<ClassModel> getClassById(String id) async {
    final response = await _client
        .from('classes')
        .select()
        .eq('id', id)
        .single();

    return ClassModel.fromJson(response);
  }

  @override
  Future<ClassModel> createClass(ClassModel classModel) async {
    final response = await _client
        .from('classes')
        .insert(classModel.toJson())
        .select()
        .single();

    return ClassModel.fromJson(response);
  }

  @override
  Future<ClassModel> updateClass(ClassModel classModel) async {
    final response = await _client
        .from('classes')
        .update(classModel.toJson())
        .eq('id', classModel.id)
        .select()
        .single();

    return ClassModel.fromJson(response);
  }

  @override
  Future<void> deleteClass(String id) async {
    await _client.from('classes').delete().eq('id', id);
  }

  @override
  Future<List<Faculty>> getFaculties() async {
    final response = await _client.from('faculties').select().order('name');

    return (response as List).map((json) => Faculty.fromJson(json)).toList();
  }

  @override
  Future<Faculty> getFacultyById(String id) async {
    final response = await _client
        .from('faculties')
        .select()
        .eq('id', id)
        .single();

    return Faculty.fromJson(response);
  }

  @override
  Future<Faculty> createFaculty(Faculty faculty) async {
    final response = await _client
        .from('faculties')
        .insert(faculty.toJson())
        .select()
        .single();

    return Faculty.fromJson(response);
  }

  @override
  Future<Faculty> updateFaculty(Faculty faculty) async {
    final response = await _client
        .from('faculties')
        .update(faculty.toJson())
        .eq('id', faculty.id)
        .select()
        .single();

    return Faculty.fromJson(response);
  }

  @override
  Future<void> deleteFaculty(String id) async {
    await _client.from('faculties').delete().eq('id', id);
  }

  @override
  Future<List<Attendance>> getAttendance() async {
    final response = await _client
        .from('attendance')
        .select()
        .order('at_time', ascending: false);

    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceByUserId(String userId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .order('at_time', ascending: false);

    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }

  @override
  Future<Attendance> createAttendance(Attendance attendance) async {
    final response = await _client
        .from('attendance')
        .insert(attendance.toJson())
        .select()
        .single();

    return Attendance.fromJson(response);
  }

  @override
  Future<void> deleteAttendance(int id) async {
    await _client.from('attendance').delete().eq('id', id);
  }

  @override
  Future<FaceEmbedding?> getFaceEmbeddingByUserId(String userId) async {
    try {
      final response = await _client
          .from('face_embeddings')
          .select()
          .eq('user_id', userId)
          .single();

      return FaceEmbedding.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<FaceEmbedding> createOrUpdateFaceEmbedding(
    FaceEmbedding faceEmbedding,
  ) async {
    final response = await _client
        .from('face_embeddings')
        .upsert(faceEmbedding.toJson())
        .select()
        .single();

    return FaceEmbedding.fromJson(response);
  }

  @override
  Future<void> deleteFaceEmbedding(String userId) async {
    await _client.from('face_embeddings').delete().eq('user_id', userId);
  }
}
