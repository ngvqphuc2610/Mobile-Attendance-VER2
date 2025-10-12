import 'package:equatable/equatable.dart';
import 'profile.dart';
import 'faculty.dart';

class Teacher extends Equatable {
  final String profileId;
  final String? facultyId;
  final String? title;
  final String? office;
  final Profile? profile;
  final Faculty? faculty;

  const Teacher({
    required this.profileId,
    this.facultyId,
    this.title,
    this.office,
    this.profile,
    this.faculty,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      profileId: json['profile_id'],
      facultyId: json['faculty_id'],
      title: json['title'],
      office: json['office'],
      profile: json['profiles'] != null 
          ? Profile.fromJson(json['profiles']) 
          : null,
      faculty: json['faculties'] != null 
          ? Faculty.fromJson(json['faculties']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'faculty_id': facultyId,
      'title': title,
      'office': office,
    };
  }

  @override
  List<Object?> get props => [
    profileId,
    facultyId,
    title,
    office,
    profile,
    faculty,
  ];
}