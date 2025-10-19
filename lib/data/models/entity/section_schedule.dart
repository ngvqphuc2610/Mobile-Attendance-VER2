import 'package:equatable/equatable.dart';

class SectionSchedule extends Equatable {
  final String id;
  final String sectionId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomId;

  const SectionSchedule({
    required this.id,
    required this.sectionId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomId,
  });

  factory SectionSchedule.fromJson(Map<String, dynamic> json) {
    return SectionSchedule(
      id: json['id'] ?? '',
      sectionId: json['section_id'] ?? '',
      dayOfWeek: _toInt(json['day_of_week']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      roomId: json['room_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room_id': roomId,
    };
  }

  static int _toInt(dynamic value) => value != null ? (value as num).toInt() : 0;

  @override
  List<Object?> get props => [id, sectionId, dayOfWeek, startTime, endTime, roomId];
}
