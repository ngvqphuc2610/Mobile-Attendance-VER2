import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//biometric đơn giản cho device một account
class BiometricGate {
  final _auth = LocalAuthentication();
  final _storage =
      const FlutterSecureStorage(); // iOS Keychain / Android Keystore

  static const _kBiometricEnabled = 'biometric_enabled';

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled ? '1' : '0');
  }

  Future<bool> getEnabled() async {
    return (await _storage.read(key: _kBiometricEnabled)) == '1';
  }

  Future<bool> authenticate({String reason = 'Xác thực để tiếp tục'}) async {
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
}
