import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class StudentScheduleEntity extends Equatable {
  final String id;
  final String sectionId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? roomId;
  final String? roomCode;
  final String? roomName;
  final String? sectionCode;
  final int? semester;
  final int? year;
  final int? subjectCredits;
  final String? subjectCode;
  final String? subjectName;

  const StudentScheduleEntity({
    required this.id,
    required this.sectionId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.startsAt,
    this.endsAt,
    this.roomId,
    this.roomCode,
    this.roomName,
    this.sectionCode,
    this.semester,
    this.year,
    this.subjectCredits,
    this.subjectCode,
    this.subjectName,
  });

  factory StudentScheduleEntity.fromJson(Map<String, dynamic> json) {
    return StudentScheduleEntity(
      id: json['id'] ?? '',
      sectionId: json['section_id'] ?? '',
      dayOfWeek: _resolveDayOfWeek(json),
      startTime: _resolveTime(json, key: 'starts_at', fallback: 'start_time'),
      endTime: _resolveTime(json, key: 'ends_at', fallback: 'end_time'),
      startsAt: _parseDateTime(json['starts_at']),
      endsAt: _parseDateTime(json['ends_at']),
      roomId: json['room_id']?.toString(),
      roomCode: json['room_code']?.toString(),
      roomName: json['room_name']?.toString(),
      sectionCode: json['section_code']?.toString(),
      semester: _toInt(json['semester']),
      year: _toInt(json['year']),
      subjectCredits: _toInt(json['subject_credits']),
      subjectCode: json['subject_code']?.toString(),
      subjectName: json['subject_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'room_id': roomId,
      'room_code': roomCode,
      'room_name': roomName,
      'section_code': sectionCode,
      'semester': semester,
      'year': year,
      'subject_credits': subjectCredits,
      'subject_code': subjectCode,
      'subject_name': subjectName,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        id,
        sectionId,
        dayOfWeek,
        startTime,
        endTime,
        startsAt,
        endsAt,
        roomId,
        roomCode,
        roomName,
        sectionCode,
        semester,
        year,
        subjectCredits,
        subjectCode,
        subjectName,
      ];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
  return DateTime.tryParse(normalized)?.toLocal();
}

int _resolveDayOfWeek(Map<String, dynamic> json) {
  final startsAt = _parseDateTime(json['starts_at']);
  if (startsAt != null) {
    return startsAt.weekday;
  }
  return StudentScheduleEntity._toInt(json['day_of_week']) ?? DateTime.monday;
}

String _resolveTime(
  Map<String, dynamic> json, {
  required String key,
  required String fallback,
}) {
  final dt = _parseDateTime(json[key]);
  if (dt != null) {
    return DateFormat('HH:mm').format(dt);
  }
  final raw = json[fallback];
  return raw?.toString() ?? '';
}
