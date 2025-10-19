import 'package:equatable/equatable.dart';

class PasswordResetToken extends Equatable {
  final String id;
  final String accountId;
  final String tokenHash;
  final DateTime expiresAt;
  final bool used;
  final DateTime createdAt;

  const PasswordResetToken({
    required this.id,
    required this.accountId,
    required this.tokenHash,
    required this.expiresAt,
    required this.used,
    required this.createdAt,
  });

  factory PasswordResetToken.fromJson(Map<String, dynamic> json) {
    return PasswordResetToken(
      id: json['id'] ?? '',
      accountId: json['account_id'] ?? '',
      tokenHash: json['token_hash'] ?? '',
      expiresAt: DateTime.parse(json['expires_at']),
      used: _toBool(json['used']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'token_hash': tokenHash,
      'expires_at': expiresAt.toIso8601String(),
      'used': used,
      'created_at': createdAt.toIso8601String(),
    };
  }

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
  List<Object?> get props =>
      [id, accountId, tokenHash, expiresAt, used, createdAt];
}
