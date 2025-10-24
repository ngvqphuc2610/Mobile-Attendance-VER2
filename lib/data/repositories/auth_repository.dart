import '../models/dto/register_otp_result.dart';
import '../models/dto/register_otp_result.dart';
import '../models/dto/totp_setup_model.dart';
import '../models/dto/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthRepository {
  Future<UserModel> login(
    String email,
    String password, {
    String? totp,
  }) async {
    try {
      return await AuthService.login(
        email,
        password,
        totp: totp,
      );
    } on NeedTotpException {
      rethrow;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<RegisterOtpResult> requestRegisterOtp({
    required RegisterRequestData data,
  }) async {
    try {
      return await AuthService.requestRegisterOtp(data: data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> verifyRegisterOtp({
    required String transactionId,
    required String otp,
  }) async {
    try {
      return await AuthService.verifyRegisterOtp(
        transactionId: transactionId,
        otp: otp,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<TotpSetupModel> initTotp() async {
    try {
      return await AuthService.initTotp();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> enableTotp({
    required String secret,
    required String token,
  }) async {
    try {
      await AuthService.enableTotp(secret: secret, token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> disableTotp(String token) async {
    try {
      await AuthService.disableTotp(token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> verifyTotp(String token) async {
    try {
      await AuthService.verifyTotp(token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      return await AuthService.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      return await AuthService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> refreshCurrentUser() async {
    try {
      return await AuthService.refreshCurrentUser();
    } catch (e) {
      return null;
    }
  }
}
