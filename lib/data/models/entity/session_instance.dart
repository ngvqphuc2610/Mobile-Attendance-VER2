import 'package:equatable/equatable.dart';

enum SessionStatus { planned, completed, cancelled }

class SessionInstance extends Equatable {
  final String id;
  final String sectionId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? roomId;
  final SessionStatus status;

  const SessionInstance({
    required this.id,
    required this.sectionId,
    required this.startsAt,
    required this.endsAt,
    this.roomId,
    required this.status,
  });

  factory SessionInstance.fromJson(Map<String, dynamic> json) {
    return SessionInstance(
      id: json['id'] ?? '',
      sectionId: json['section_id'] ?? '',
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      roomId: json['room_id'],
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'room_id': roomId,
      'status': status.name,
    };
  }

  static SessionStatus _parseStatus(dynamic value) {
    final statusValue = (value ?? '').toString().toLowerCase();
    switch (statusValue) {
      case 'completed':
        return SessionStatus.completed;
      case 'cancelled':
        return SessionStatus.cancelled;
      case 'planned':
      default:
        return SessionStatus.planned;
    }
  }

  @override
  List<Object?> get props => [id, sectionId, startsAt, endsAt, roomId, status];
}
