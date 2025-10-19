import 'package:equatable/equatable.dart';
import 'profile_entity.dart';

class StudentEntity extends Equatable {
  final String profileId;
  final String? classId;
  final String? mssv;
  final int? mssvCohort;
  final String? mssvTrackCode;
  final int? mssvSerial;
  final ProfileEntity? profile;

  const StudentEntity({
    required this.profileId,
    this.classId,
    this.mssv,
    this.mssvCohort,
    this.mssvTrackCode,
    this.mssvSerial,
    this.profile,
  });

  factory StudentEntity.fromJson(Map<String, dynamic> json) {
    ProfileEntity? profile;
    final rawProfile = json['profile'];

    if (rawProfile is Map<String, dynamic>) {
      profile = ProfileEntity.fromJson(rawProfile);
    } else if (json.containsKey('full_name') || json.containsKey('code')) {
      profile = ProfileEntity(
        id: json['profile_id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        classId: json['class_id']?.toString(),
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
      );
    }

    return StudentEntity(
      profileId: json['profile_id']?.toString() ?? '',
      classId: json['class_id']?.toString(),
      mssv: json['mssv']?.toString(),
      mssvCohort: json['mssv_cohort'] != null ? int.tryParse(json['mssv_cohort'].toString()) : null,
      mssvTrackCode: json['mssv_track_code']?.toString(),
      mssvSerial: json['mssv_serial'] != null ? int.tryParse(json['mssv_serial'].toString()) : null,
      profile: profile,
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
      'profile': profile?.toJson(),
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
      ];
}
