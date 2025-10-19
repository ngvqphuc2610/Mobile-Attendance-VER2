import '../models/entity/account_entity.dart';
import '../services/account_service.dart';

/// Repository định nghĩa các thao tác dữ liệu cấp domain cho Tài khoản.
/// - Nhận dữ liệu từ Service (JSON/Map) và map sang AccountEntity.
/// - Đồng bộ chữ ký hàm với AccountService.
abstract class AccountRepository {
  Future<List<AccountEntity>> getAccounts({String? role, String? search});

  Future<AccountEntity> createAccount({
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
  });

  Future<AccountEntity> updateAccount({
    required String userId, // đồng bộ tên với AccountService
    required String email,
    required String fullName,
    required String code,
    required String role,
    String? password,
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
  });

  Future<void> deleteAccount(String userId);

  // Các thao tác bổ sung đã có trong Service
  Future<void> toggleAccountStatus(String userId);
  Future<void> resetPassword(String userId, {String? password});
  Future<void> disableAccount(String userId, {String? action});
}

class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<List<AccountEntity>> getAccounts({
    String? role,
    String? search,
  }) async {
    try {
      final list = await AccountService.getAccounts(role: role, search: search);
      return list.map((e) => AccountEntity.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch accounts: $e');
    }
  }

  @override
  Future<AccountEntity> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String code,
    required String role,
    String? phone,
    String? classId,
    String? mssv,
    String? facultyId,
    String? title,
    String? office,
  }) async {
    try {
      final json = await AccountService.createAccount(
        email: email,
        password: password,
        fullName: fullName,
        code: code,
        role: role,
        phone: phone,
        classId: classId,
        mssv: mssv,
        facultyId: facultyId,
        title: title,
        office: office,
      );
      return AccountEntity.fromJson(json);
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  @override
  Future<AccountEntity> updateAccount({
    required String userId,
    required String email,
    required String fullName,
    required String code,
    required String role,
    String? password,
    String? phone,
    String? classId,
    String? mssv,
    String? facultyId,
    String? title,
    String? office,
    bool resetPassword = false,
    bool newEmail = false,
  }) async {
    try {
      final json = await AccountService.updateAccount(
        userId: userId,
        email: email,
        password: password,
        fullName: fullName,
        code: code,
        role: role,
        phone: phone,
        classId: classId,
        mssv: mssv,
        facultyId: facultyId,
        title: title,
        office: office,
        resetPassword: resetPassword,
        newEmail: newEmail,
      );
      return AccountEntity.fromJson(json);
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      await AccountService.deleteAccount(userId);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  @override
  Future<void> toggleAccountStatus(String userId) async {
    try {
      await AccountService.toggleAccountStatus(userId);
    } catch (e) {
      throw Exception('Failed to toggle status: $e');
    }
  }

  @override
  Future<void> resetPassword(String userId, {String? password}) async {
    try {
      await AccountService.resetPassword(userId, password: password);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<void> disableAccount(String userId, {String? action}) async {
    try {
      await AccountService.disableAccount(userId, action: action);
    } catch (e) {
      throw Exception('Failed to disable account: $e');
    }
  }
}
