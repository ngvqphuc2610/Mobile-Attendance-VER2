
import '../models/entity/session_checkin_token.dart';
import '../services/session_checkin_token_service.dart';

class SessionCheckinTokenRepository {
  Future<List<SessionCheckinToken>> getSessionCheckinTokens({
    String? sessionId,
  }) async {
    return await SessionCheckinTokenService.fetchSessionCheckinTokens(
      sessionId: sessionId,
    );
  }

  Future<SessionCheckinToken> openSessionCheckinToken({
    required String sessionId,
    int durationSeconds = 180,
  }) async {
    return await SessionCheckinTokenService.openSessionCheckinToken(
      sessionId: sessionId,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> closeSessionCheckinToken({
    required String sessionId,
  }) async {
    return await SessionCheckinTokenService.closeSessionCheckinToken(
      sessionId: sessionId,
    );
  }

  Future<void> extendSessionCheckinToken({
    required String sessionId,
    int addSeconds = 120,
  }) async {
    return await SessionCheckinTokenService.extendSessionCheckinToken(
      sessionId: sessionId,
      addSeconds: addSeconds,
    );
  }
}