import 'package:equatable/equatable.dart';

class TotpSetupModel extends Equatable {
  final String secret;
  final String otpauthUrl;
  final String qrDataUrl;

  const TotpSetupModel({
    required this.secret,
    required this.otpauthUrl,
    required this.qrDataUrl,
  });

  factory TotpSetupModel.fromJson(Map<String, dynamic> json) {
    return TotpSetupModel(
      secret: json['secret'] ?? '',
      otpauthUrl: json['otpauthUrl'] ?? json['otpauth_url'] ?? '',
      qrDataUrl: json['qrDataUrl'] ?? json['qrDataURL'] ?? json['qr_data_url'] ?? '',
    );
  }

  @override
  List<Object?> get props => [secret, otpauthUrl, qrDataUrl];
}
