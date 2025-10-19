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
    return TeacherEntity(
      profileId: json['profile_id']?.toString() ?? '',
      facultyId: json['faculty_id']?.toString(),
      title: json['title']?.toString(),
      office: json['office']?.toString(),
      profile: json['profile'] != null ? ProfileEntity.fromJson(json['profile']) : null,
      faculty: json['faculty'] != null ? FacultyEntity.fromJson(json['faculty']) : null,
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