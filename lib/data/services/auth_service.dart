import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  static UserModel? _currentUser;
  
  static UserModel? get currentUser => _currentUser;
  
  static Future<UserModel> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      
      final user = UserModel.fromJson(response['user']);
      final token = response['token'];
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, user.toJson().toString());
      
      _currentUser = user;
      
      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
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
    
    try {
      _currentUser = await ApiService.getCurrentUser();
      return _currentUser;
    } catch (e) {
      return null;
    }
  }
}