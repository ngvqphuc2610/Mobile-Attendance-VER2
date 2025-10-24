import '../../../data/repositories/auth_repository.dart';
import '../../entities/result.dart';

class VerifyTotpUsecase {
  final AuthRepository _authRepository;

  VerifyTotpUsecase(this._authRepository);

  /// Gửi mã TOTP người dùng nhập để xác minh
  Future<Result<void>> call(String token) async {
    try {
      await _authRepository.verifyTotp(token);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
