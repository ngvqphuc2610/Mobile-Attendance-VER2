import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class AccountService {
  static Future<List<Map<String, dynamic>>> getAccounts({
    String? role,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (role != null) queryParams['role'] = role;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    return await ApiService.getList(ApiConstants.accounts, queryParams: queryParams);
  }
  
  static Future<Map<String, dynamic>> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String code,
    required String role,
    String? phone,
    // Student specific
    String? classId,
    String? mssv,
    // Teacher specific
    String? facultyId,
    String? title,
    String? office,
  }) async {
    return await ApiService.create(ApiConstants.accounts, {
      'email': email,
      'password': password,
      'full_name': fullName,
      'code': code,
      'role': role,
      'phone': phone,
      'class_id': classId,
      'mssv': mssv,
      'faculty_id': facultyId,
      'title': title,
      'office': office,
    });
  }
  
  static Future<Map<String, dynamic>> toggleAccountStatus(String id) async {
    return await ApiService.patch(ApiConstants.accounts, id, 'toggle');
  }
  
  static Future<Map<String, dynamic>> resetPassword(String id, {String? password}) async {
    return await ApiService.patch(ApiConstants.accounts, id, 'reset-password', 
      data: password != null ? {'password': password} : null);
  }
  static Future<Map<String, dynamic>> disableAccount(String id, {String? action}) async {
    return await ApiService.patch(ApiConstants.accounts, id, action ?? 'disable');
  }
  
  static Future<Map<String, dynamic>> deleteAccount(String id) async {
    return await ApiService.delete(ApiConstants.accounts, id);
  }
  static Future<Map<String, dynamic>> updateAccount({
    required String userId,
    required String email,
    String? password,
    required String fullName,
    required String code,
    required String role,
    String? phone,
    // Student specific
    String? classId,
    String? mssv,
    // Teacher specific
    String? facultyId,
    String? title,
    String? office,
    bool resetPassword = false,
    bool newEmail = false,
  }) async {
    return await ApiService.update(ApiConstants.accounts, userId, {
      'email': email,
      'password': password,
      'full_name': fullName,
      'code': code,
      'role': role,
      'phone': phone,
      'class_id': classId,
      'mssv': mssv,
      'faculty_id': facultyId,
      'title': title,
      'office': office,
      'reset_password': resetPassword,
      'new_email': newEmail,
    });
  }
  
}
