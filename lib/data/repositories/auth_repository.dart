import '../models/dto/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    try {
      return await AuthService.login(email, password);
    } catch (e) {
      throw Exception('Login failed: $e');
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
}
