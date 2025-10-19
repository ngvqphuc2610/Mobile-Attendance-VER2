import 'package:equatable/equatable.dart';
import 'profile_entity.dart';
import 'faculty_entity.dart';

class TeacherEntity extends Equatable {
  final String profileId;
  final String? facultyId;
  final String? title;
  final String? office;
  final ProfileEntity? profile;
  final FacultyEntity? faculty;

  const TeacherEntity({
    required this.profileId,
    this.facultyId,
    this.title,
    this.office,
    this.profile,
    this.faculty,
  });

  factory TeacherEntity.fromJson(Map<String, dynamic> json) {
    ProfileEntity? profile;
    final rawProfile = json['profile'];
    if (rawProfile is Map<String, dynamic>) {
      profile = ProfileEntity.fromJson(rawProfile);
    } else if (json.containsKey('full_name') || json.containsKey('code')) {
      profile = ProfileEntity(
        id: json['profile_id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        classId: null,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
      );
    }

    FacultyEntity? faculty;
    final rawFaculty = json['faculty'];
    if (rawFaculty is Map<String, dynamic>) {
      faculty = FacultyEntity.fromJson(rawFaculty);
    } else if (json.containsKey('faculty_name') || json.containsKey('faculty_code')) {
      faculty = FacultyEntity(
        id: json['faculty_id']?.toString() ?? '',
        code: json['faculty_code']?.toString() ?? '',
        name: json['faculty_name']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['faculty_created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    }

    return TeacherEntity(
      profileId: json['profile_id']?.toString() ?? '',
      facultyId: json['faculty_id']?.toString(),
      title: json['title']?.toString(),
      office: json['office']?.toString(),
      profile: profile,
      faculty: faculty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'faculty_id': facultyId,
      'title': title,
      'office': office,
      'profile': profile?.toJson(),
      'faculty': faculty?.toJson(),
    };
  }

  @override
  List<Object?> get props => [profileId, facultyId, title, office, profile, faculty];
}
