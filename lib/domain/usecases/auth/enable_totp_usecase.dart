import '../../../data/models/dto/totp_setup_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../entities/result.dart';

class EnableTotpUsecase {
  final AuthRepository _authRepository;

  EnableTotpUsecase(this._authRepository);

  Future<Result<TotpSetupModel>> call() async {
    try {
      final setup = await _authRepository.initTotp();
      return Result.success(setup);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> verify({
    required String secret,
    required String token,
  }) async {
    try {
      await _authRepository.enableTotp(secret: secret, token: token);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}