import 'package:equatable/equatable.dart';
import 'profile.dart';
import 'class_model.dart';

class Student extends Equatable {
  final String profileId;
  final String? classId;
  final String? mssv;
  final int? mssvCohort;
  final String? mssvTrackCode;
  final int? mssvSerial;
  final Profile? profile;
  final ClassModel? classInfo;

  const Student({
    required this.profileId,
    this.classId,
    this.mssv,
    this.mssvCohort,
    this.mssvTrackCode,
    this.mssvSerial,
    this.profile,
    this.classInfo,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      profileId: json['profile_id'],
      classId: json['class_id'],
      mssv: json['mssv'],
      mssvCohort: json['mssv_cohort'],
      mssvTrackCode: json['mssv_track_code'],
      mssvSerial: json['mssv_serial'],
      profile: json['profiles'] != null 
          ? Profile.fromJson(json['profiles']) 
          : null,
      classInfo: json['classes'] != null 
          ? ClassModel.fromJson(json['classes']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'class_id': classId,
      'mssv': mssv,
      'mssv_cohort': mssvCohort,
      'mssv_track_code': mssvTrackCode,
      'mssv_serial': mssvSerial,
    };
  }

  @override
  List<Object?> get props => [
    profileId,
    classId,
    mssv,
    mssvCohort,
    mssvTrackCode,
    mssvSerial,
    profile,
    classInfo,
  ];
}