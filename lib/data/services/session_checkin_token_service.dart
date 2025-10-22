import '../../core/constants/api_constants.dart';
import '../models/entity/session_checkin_token.dart';
import 'api_service.dart';

class SessionCheckinTokenService {
  static Future<List<SessionCheckinToken>> fetchSessionCheckinTokens({
    String? sessionId,
  }) async {
    final queryParams = <String, String>{};
    if (sessionId != null && sessionId.isNotEmpty) {
      queryParams['session_id'] = sessionId;
    }

    final response = await ApiService.getList(
      ApiConstants.sessionCheckinTokens, // nhớ sửa tên hằng "checkin" (không phải "checking")
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    // Đảm bảo cast List<Map<String,dynamic>>
    return (response as List)
        .map((e) => SessionCheckinToken.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList(growable: false);
  }

  static Future<SessionCheckinToken> openSessionCheckinToken({
    required String sessionId,
    int durationSeconds = 180,
  }) async {
    // Backend trả 201 + { message, token: {...} }
    final resp = await ApiService.create(
      ApiConstants.sessionCheckinTokensOpen,
      {'session_id': sessionId, 'duration_seconds': durationSeconds},
    );

    final tokenMap = (resp['token'] ?? resp) as Map<String, dynamic>;
    return SessionCheckinToken.fromJson(tokenMap);
  }

  static Future<void> closeSessionCheckinToken({
    required String sessionId,
  }) async {
    // Dùng postExpectOk() vì backend trả 200
    await ApiService.postExpectOk(
      ApiConstants.sessionCheckinTokensClose,
      {'session_id': sessionId},
    );
  }

  static Future<void> extendSessionCheckinToken({
    required String sessionId,
    int addSeconds = 120,
  }) async {
    await ApiService.postExpectOk(
      ApiConstants.sessionCheckinTokensExtend,
      {'session_id': sessionId, 'add_seconds': addSeconds},
    );
  }
}
