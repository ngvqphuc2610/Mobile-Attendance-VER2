import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createAccount({
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
    final response = await _supabase.functions.invoke(
      'create_account',
      body: {
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
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to create account');
    }

    return response.data;
  }

  Future<Map<String, dynamic>> updateAccount({
    required String userId,
    String? email,
    String? password,
    String? fullName,
    String? code,
    String? phone,
    String? role,
    // Student specific
    String? classId,
    String? mssv,
    // Teacher specific
    String? facultyId,
    String? title,
    String? office,
    // Actions
    bool resetPassword = false,
    String? newEmail,
  }) async {
    final response = await _supabase.functions.invoke(
      'update_account',
      body: {
        'user_id': userId,
        'email': email,
        'password': password,
        'full_name': fullName,
        'code': code,
        'phone': phone,
        'role': role,
        'class_id': classId,
        'mssv': mssv,
        'faculty_id': facultyId,
        'title': title,
        'office': office,
        'reset_password': resetPassword,
        'new_email': newEmail,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to update account');
    }

    return response.data;
  }

  Future<Map<String, dynamic>> disableAccount({
    required String userId,
    required String action, // 'disable', 'enable', 'delete'
  }) async {
    final response = await _supabase.functions.invoke(
      'disable_account',
      body: {
        'user_id': userId,
        'action': action,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to process account action');
    }

    return response.data;
  }

  Future<List<Map<String, dynamic>>> getAccounts({
    String? search,
    String? roleFilter,
  }) async {
    var query = _supabase
        .from('profiles')
        .select('''
          id, code, full_name, is_active, email, phone, created_at,
          user_roles(role),
          students(mssv, class_id, classes(id, name, code)),
          teachers(faculty_id, title, office, faculties(id, name, code))
        ''');

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'full_name.ilike.%$search%,'
        'code.ilike.%$search%,'
        'email.ilike.%$search%'
      );
    }

    final response = await query.order('full_name');
    
    List<Map<String, dynamic>> accounts = List<Map<String, dynamic>>.from(response);
    
    // Filter by role if specified
    if (roleFilter != null && roleFilter.isNotEmpty) {
      accounts = accounts.where((account) {
        final userRoles = account['user_roles'] as List?;
        if (userRoles == null || userRoles.isEmpty) return false;
        return userRoles.first['role'] == roleFilter;
      }).toList();
    }

    return accounts;
  }

  Future<Map<String, dynamic>?> getAccountById(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('''
          id, code, full_name, is_active, email, phone, created_at,
          user_roles(role),
          students(mssv, class_id, classes(id, name, code)),
          teachers(faculty_id, title, office, faculties(id, name, code))
        ''')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }
}