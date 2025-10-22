import 'package:equatable/equatable.dart';

DateTime _parseDbDate(dynamic v) {
  if (v == null) throw FormatException('null datetime');
  final s = v.toString().trim();
  // Nếu là ISO -> parse thẳng
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();

  // Nếu dạng "YYYY-MM-DD HH:mm:ss" -> đổi sang ISO
  final normalized = s.contains(' ') ? s.replaceFirst(' ', 'T') : s;
  final iso2 = DateTime.tryParse(normalized);
  if (iso2 != null) return iso2.toLocal();

  throw FormatException('Unrecognized datetime format: $s');
}

class SessionCheckinToken extends Equatable {
  final String id;
  final String sessionId;
  final String pin4;
  final String nonce;
  final DateTime expiresAt;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  const SessionCheckinToken({
    required this.id,
    required this.sessionId,
    required this.pin4,
    required this.nonce,
    required this.expiresAt,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory SessionCheckinToken.fromJson(Map<String, dynamic> json) {
    return SessionCheckinToken(
      id: (json['id'] ?? '').toString(),
      sessionId: (json['session_id'] ?? '').toString(),
      pin4: (json['pin_4'] ?? '').toString(),
      nonce: (json['nonce'] ?? '').toString(),
      expiresAt: _parseDbDate(json['expires_at']),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdBy: (json['created_by'] ?? '').toString(),
      createdAt: _parseDbDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'pin_4': pin4,
      'nonce': nonce,
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id, sessionId, pin4, nonce, expiresAt, isActive, createdBy, createdAt,
      ];
}
