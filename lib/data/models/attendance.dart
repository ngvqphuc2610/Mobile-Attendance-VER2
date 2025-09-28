import 'package:equatable/equatable.dart';

enum AttendanceMethod { face, barcode, manual }

class Attendance extends Equatable {
  final int id;
  final String? userId;
  final AttendanceMethod method;
  final double? confidenceScore;
  final DateTime atTime;
  final String? note;

  const Attendance({
    required this.id,
    this.userId,
    required this.method,
    this.confidenceScore,
    required this.atTime,
    this.note,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['user_id'],
      method: _parseAttendanceMethod(json['method']),
      confidenceScore: json['confidence_score']?.toDouble(),
      atTime: DateTime.parse(json['at_time']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method': method.name,
      'confidence_score': confidenceScore,
      'at_time': atTime.toIso8601String(),
      'note': note,
    };
  }

  static AttendanceMethod _parseAttendanceMethod(String method) {
    switch (method) {
      case 'face':
        return AttendanceMethod.face;
      case 'barcode':
        return AttendanceMethod.barcode;
      case 'manual':
        return AttendanceMethod.manual;
      default:
        return AttendanceMethod.manual;
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    method,
    confidenceScore,
    atTime,
    note,
  ];
}
