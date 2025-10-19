import 'package:equatable/equatable.dart';

class MssvSchemeRule extends Equatable {
  final String id;
  final int cohortFrom;
  final int cohortTo;
  final String trackCode;
  final String? facultyId;
  final String programTrackId;
  final int priority;
  final bool active;
  final String? note;

  const MssvSchemeRule({
    required this.id,
    required this.cohortFrom,
    required this.cohortTo,
    required this.trackCode,
    this.facultyId,
    required this.programTrackId,
    required this.priority,
    required this.active,
    this.note,
  });

  factory MssvSchemeRule.fromJson(Map<String, dynamic> json) {
    return MssvSchemeRule(
      id: json['id'] ?? '',
      cohortFrom: _toInt(json['cohort_from']),
      cohortTo: _toInt(json['cohort_to']),
      trackCode: json['track_code'] ?? '',
      facultyId: json['faculty_id'],
      programTrackId: json['program_track_id'] ?? '',
      priority: _toInt(json['priority']),
      active: _toBool(json['active']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cohort_from': cohortFrom,
      'cohort_to': cohortTo,
      'track_code': trackCode,
      'faculty_id': facultyId,
      'program_track_id': programTrackId,
      'priority': priority,
      'active': active,
      'note': note,
    };
  }

  static int _toInt(dynamic value) => value != null ? (value as num).toInt() : 0;

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true';
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        cohortFrom,
        cohortTo,
        trackCode,
        facultyId,
        programTrackId,
        priority,
        active,
        note,
      ];
}
