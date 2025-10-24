import 'package:equatable/equatable.dart';

class RegisterRequestData extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String? code;
  final String? phone;
  final String? role;

  const RegisterRequestData({
    required this.fullName,
    required this.email,
    required this.password,
    this.code,
    this.phone,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (code != null && code!.isNotEmpty) 'code': code,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (role != null && role!.isNotEmpty) 'role': role,
      };

  RegisterRequestData copyWith({
    String? fullName,
    String? email,
    String? password,
    String? code,
    String? phone,
    String? role,
  }) {
    return RegisterRequestData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      code: code ?? this.code,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [fullName, email, password, code, phone, role];
}

class RegisterOtpResult extends Equatable {
  final String transactionId;
  final int expiresIn;
  final RegisterRequestData requestData;
  final String? message;

  const RegisterOtpResult({
    required this.transactionId,
    required this.expiresIn,
    required this.requestData,
    this.message,
  });

  @override
  List<Object?> get props => [transactionId, expiresIn, requestData, message];
}
