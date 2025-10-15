class AttendanceModel {
  final int id;
  final String? userId;
  final String? fullName;
  final String? code;
  final String method;
  final double? confidenceScore;
  final DateTime atTime;
  final String? note;

  AttendanceModel({
    required this.id,
    this.userId,
    this.fullName,
    this.code,
    required this.method,
    this.confidenceScore,
    required this.atTime,
    this.note,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      fullName: json['full_name'],
      code: json['code'],
      method: json['method'] ?? '',
      confidenceScore: json['confidence_score']?.toDouble(),
      atTime: DateTime.parse(json['at_time']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'code': code,
      'method': method,
      'confidence_score': confidenceScore,
      'at_time': atTime.toIso8601String(),
      'note': note,
    };
  }
}