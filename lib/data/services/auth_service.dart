import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dto/register_otp_result.dart';
import '../models/dto/totp_setup_model.dart';
import '../models/dto/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  static UserModel? _currentUser;
  
  static UserModel? get currentUser => _currentUser;
  
  static Future<UserModel> login(
    String email,
    String password, {
    String? totp,
  }) async {
    try {
      final response =
          await ApiService.login(email, password, totp: totp);
      final user = UserModel.fromJson(response['user']);
      final token = response['token'];
      await _persistSession(token, user);
      return user;
    } on NeedTotpException {
      rethrow;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<RegisterOtpResult> requestRegisterOtp({
    required RegisterRequestData data,
  }) async {
    try {
      final resp = await ApiService.requestRegisterOtp(data.toJson());
      final transactionId =
          (resp['transactionId'] ?? resp['transaction_id'])?.toString();
      if (transactionId == null || transactionId.isEmpty) {
        throw Exception('Thiếu mã transaction');
      }
      final expiresRaw = resp['expiresIn'] ?? resp['expires_in'];
      final expiresIn = expiresRaw is num
          ? expiresRaw.toInt()
          : int.tryParse(expiresRaw?.toString() ?? '') ?? 300;
      final message = resp['message']?.toString();
      return RegisterOtpResult(
        transactionId: transactionId,
        expiresIn: expiresIn,
        requestData: data,
        message: message,
      );
    } catch (e) {
      throw Exception('Gửi OTP đăng ký thất bại: $e');
    }
  }

  static Future<UserModel> verifyRegisterOtp({
    required String transactionId,
    required String otp,
  }) async {
    try {
      final resp = await ApiService.verifyRegisterOtp(
        transactionId: transactionId,
        otp: otp,
      );
      final token = resp['token']?.toString();
      final user = UserModel.fromJson(resp['user']);
      if (token == null || token.isEmpty) {
        throw Exception('Thiếu token trả về từ máy chủ');
      }
      await _persistSession(token, user);
      return user;
    } catch (e) {
      throw Exception('Xác thực OTP thất bại: $e');
    }
  }

  static Future<TotpSetupModel> initTotp() async {
    try {
      final resp = await ApiService.initTotp();
      return TotpSetupModel.fromJson(resp);
    } catch (e) {
      throw Exception('Không thể khởi tạo TOTP: $e');
    }
  }

  static Future<void> enableTotp({
    required String secret,
    required String token,
  }) async {
    try {
      await ApiService.enableTotp(secret: secret, token: token);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(totpEnabled: true);
        await _cacheUser(_currentUser!);
      } else {
        await refreshCurrentUser();
      }
    } catch (e) {
      throw Exception('Không thể bật TOTP: $e');
    }
  }

  static Future<void> disableTotp(String token) async {
    try {
      await ApiService.disableTotp(token);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(totpEnabled: false);
        await _cacheUser(_currentUser!);
      } else {
        await refreshCurrentUser();
      }
    } catch (e) {
      throw Exception('Không thể tắt TOTP: $e');
    }
  }

  static Future<void> verifyTotp(String token) async {
    try {
      await ApiService.verifyTotp(token);
    } catch (e) {
      throw Exception('Không thể xác thực TOTP: $e');
    }
  }
  
  static Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    }
    
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    
    _currentUser = null;
    ApiService.clearToken();
  }
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      ApiService.setToken(token);
      
      try {
        _currentUser = await ApiService.getCurrentUser();
        return true;
      } catch (e) {
        // Token might be expired, clear it
        await logout();
        return false;
      }
    }
    
    return false;
  }
  
  static Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_userKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map);
        return _currentUser;
      } catch (_) {}
    }
    
    try {
      _currentUser = await ApiService.getCurrentUser();
      if (_currentUser != null) {
        await _cacheUser(_currentUser!);
      }
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel?> refreshCurrentUser() async {
    try {
      final user = await ApiService.getCurrentUser();
      _currentUser = user;
      await _cacheUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistSession(
    String token,
    UserModel user,
  ) async {
    ApiService.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _currentUser = user;
  }

  static Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
