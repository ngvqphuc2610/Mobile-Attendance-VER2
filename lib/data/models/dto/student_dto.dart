import 'package:equatable/equatable.dart';

class StudentDto extends Equatable {
  final String? profileId;
  final String? classId;
  final String? mssv;
  final int? mssvCohort;
  final String? mssvTrackCode;
  final int? mssvSerial;
  final String? fullName;
  final String? code;
  final String? email;
  final String? phone;
  final bool? isActive;

  const StudentDto({
    this.profileId,
    this.classId,
    this.mssv,
    this.mssvCohort,
    this.mssvTrackCode,
    this.mssvSerial,
    this.fullName,
    this.code,
    this.email,
    this.phone,
    this.isActive,
  });

  factory StudentDto.fromJson(Map<String, dynamic> json) {
    return StudentDto(
      profileId: json['profile_id']?.toString(),
      classId: json['class_id']?.toString(),
      mssv: json['mssv']?.toString(),
      mssvCohort: json['mssv_cohort'] != null ? int.tryParse(json['mssv_cohort'].toString()) : null,
      mssvTrackCode: json['mssv_track_code']?.toString(),
      mssvSerial: json['mssv_serial'] != null ? int.tryParse(json['mssv_serial'].toString()) : null,
      fullName: json['full_name']?.toString(),
      code: json['code']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (profileId != null) data['profile_id'] = profileId;
    if (classId != null) data['class_id'] = classId;
    if (mssv != null) data['mssv'] = mssv;
    if (mssvCohort != null) data['mssv_cohort'] = mssvCohort;
    if (mssvTrackCode != null) data['mssv_track_code'] = mssvTrackCode;
    if (mssvSerial != null) data['mssv_serial'] = mssvSerial;
    if (fullName != null) data['full_name'] = fullName;
    if (code != null) data['code'] = code;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (isActive != null) data['is_active'] = isActive;
    
    return data;
  }

  @override
  List<Object?> get props => [
        profileId,
        classId,
        mssv,
        mssvCohort,
        mssvTrackCode,
        mssvSerial,
        fullName,
        code,
        email,
        phone,
        isActive,
      ];
}