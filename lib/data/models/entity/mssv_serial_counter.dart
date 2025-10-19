import 'package:equatable/equatable.dart';

class MssvSerialCounter extends Equatable {
  final int cohortYear;
  final String trackCode;
  final String facultyId;
  final int nextSerial;

  const MssvSerialCounter({
    required this.cohortYear,
    required this.trackCode,
    required this.facultyId,
    required this.nextSerial,
  });

  factory MssvSerialCounter.fromJson(Map<String, dynamic> json) {
    return MssvSerialCounter(
      cohortYear: _toInt(json['cohort_year']),
      trackCode: json['track_code'] ?? '',
      facultyId: json['faculty_id'] ?? '',
      nextSerial: _toInt(json['next_serial']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cohort_year': cohortYear,
      'track_code': trackCode,
      'faculty_id': facultyId,
      'next_serial': nextSerial,
    };
  }

  static int _toInt(dynamic value) => value != null ? (value as num).toInt() : 0;

  @override
  List<Object?> get props => [cohortYear, trackCode, facultyId, nextSerial];
}
