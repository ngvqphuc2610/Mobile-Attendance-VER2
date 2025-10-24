import '../../../data/repositories/auth_repository.dart';
import '../../entities/result.dart';

class DisableTotpUsecase {
  final AuthRepository _authRepository;

  DisableTotpUsecase(this._authRepository);

  Future<Result<void>> call(String token) async {
    try {
      await _authRepository.disableTotp(token);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}