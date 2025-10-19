import 'package:equatable/equatable.dart';

class TeacherDto extends Equatable {
  final String? profileId;
  final String? facultyId;
  final String? title;
  final String? office;
  final String? fullName;
  final String? code;
  final String? email;
  final String? phone;
  final bool? isActive;

  const TeacherDto({
    this.profileId,
    this.facultyId,
    this.title,
    this.office,
    this.fullName,
    this.code,
    this.email,
    this.phone,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (profileId != null) data['profile_id'] = profileId;
    if (facultyId != null) data['faculty_id'] = facultyId;
    if (title != null) data['title'] = title;
    if (office != null) data['office'] = office;
    if (fullName != null) data['full_name'] = fullName;
    if (code != null) data['code'] = code;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (isActive != null) data['is_active'] = isActive;
    
    return data;
  }

  @override
  List<Object?> get props => [profileId, facultyId, title, office, fullName, code, email, phone, isActive];
}