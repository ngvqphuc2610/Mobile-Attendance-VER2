import 'package:equatable/equatable.dart';

enum AttendanceMethod { face, barcode, manual }

class AttendanceEntity extends Equatable {
  final String id;
  final String? userId;
  final String? userFullName;
  final String? userCode;
  final AttendanceMethod method;
  final double? confidenceScore;
  final DateTime atTime;
  final String? note;
  final String? sectionId;
  final String? sessionId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? address;
  


  const AttendanceEntity({
    required this.id,
    this.userId,
    required this.method,
    this.userFullName,
    this.userCode,
    this.confidenceScore,
    required this.atTime,
    this.note,
    this.sectionId,
    this.sessionId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.address,
  });

  factory AttendanceEntity.fromJson(Map<String, dynamic> json) {
    return AttendanceEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      method: _parseMethod(json['method']?.toString()),
      userFullName: json['full_name']?.toString(),
      userCode: json['code']?.toString(),
      confidenceScore: json['confidence_score'] != null 
          ? double.tryParse(json['confidence_score'].toString())
          : null,
      atTime: DateTime.tryParse(json['at_time']?.toString() ?? '') ?? DateTime.now(),
      note: json['note']?.toString(),
      sectionId: json['section_id']?.toString(),
      sessionId: json['session_id']?.toString(),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      accuracyMeters: json['accuracy_m'] != null ? (json['accuracy_m'] as num).toDouble() : null,
      address: json['address']?.toString(),
    );
  }

  static AttendanceMethod _parseMethod(String? method) {
    switch (method?.toLowerCase()) {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method': method.name,
      'full_name': userFullName,
      'code': userCode,
      'confidence_score': confidenceScore,
      'at_time': atTime.toIso8601String(),
      'note': note,
      'section_id': sectionId,
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_m': accuracyMeters,
      'address': address,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userFullName,
        userCode,
        method,
        confidenceScore,
        atTime,
        note,
        sectionId,
        sessionId,
        latitude,
        longitude,
        accuracyMeters,
        address,
      ];
}
