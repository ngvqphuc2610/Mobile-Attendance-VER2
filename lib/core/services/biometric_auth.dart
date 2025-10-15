import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

//biometric cho nhiều account trên device
class BiometricAccount {
  final String userId;
  final String email;
  final String password;
  final String fullName;
  final String role;

  const BiometricAccount({
    required this.userId,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
      };

  factory BiometricAccount.fromJson(Map<String, dynamic> json) {
    return BiometricAccount(
      userId: json['userId'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: (json['fullName'] ?? '') as String,
      role: (json['role'] ?? '') as String,
    );
  }
}

class BiometricAuth {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const AndroidOptions _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);
  static const IOSOptions _iosOptions = IOSOptions();

  static const String _accountPrefix = 'biometric_account_';
  static const String _enabledPrefix = 'biometric_enabled_';

  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({
    String reason = 'Xác thực để đăng nhập',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveAccount(BiometricAccount account) async {
    await _storage.write(
      key: '$_accountPrefix${account.userId}',
      value: jsonEncode(account.toJson()),
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await setEnabled(account.userId, true);
  }

  static Future<void> deleteAccount(String userId) async {
    await _storage.delete(
      key: '$_accountPrefix$userId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await setEnabled(userId, false);
  }

  static Future<void> setEnabled(String userId, bool enabled) async {
    await _storage.write(
      key: '$_enabledPrefix$userId',
      value: enabled ? 'true' : 'false',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static Future<bool> isEnabled(String userId) async {
    final value = await _storage.read(
      key: '$_enabledPrefix$userId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    return value == 'true';
  }

  static Future<List<BiometricAccount>> getAccounts() async {
    final entries = await _storage.readAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    final accounts = <BiometricAccount>[];
    for (final entry in entries.entries) {
      if (entry.key.startsWith(_accountPrefix) && entry.value != null) {
        try {
          final data = jsonDecode(entry.value!) as Map<String, dynamic>;
          accounts.add(BiometricAccount.fromJson(data));
        } catch (_) {
          // Skip malformed record
        }
      }
    }
    return accounts;
  }

  static Future<BiometricAccount?> getAccount(String userId) async {
    final value = await _storage.read(
      key: '$_accountPrefix$userId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    if (value == null) return null;
    try {
      return BiometricAccount.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
