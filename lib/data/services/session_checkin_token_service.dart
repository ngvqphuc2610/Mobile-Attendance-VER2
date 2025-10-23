import '../../core/constants/api_constants.dart';
import '../models/entity/session_checkin_token.dart';
import 'api_service.dart';

class SessionCheckinTokenService {
  /// Lấy danh sách token đang mở (có thể filter theo session_id)
  static Future<List<SessionCheckinToken>> fetchSessionCheckinTokens({
    String? sessionId,
  }) async {
    final queryParams = <String, String>{};
    if (sessionId != null && sessionId.isNotEmpty) {
      queryParams['session_id'] = sessionId;
    }

    final resp = await ApiService.getList(
      ApiConstants
          .sessionCheckinTokens, // nhớ là "checkin", không phải "checking"
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (resp is! List) {
      throw Exception(
        'Unexpected response: expected a List but got ${resp.runtimeType}',
      );
    }

    // Mỗi item phải là Map<String, dynamic>
    return resp
        .map<SessionCheckinToken>((e) {
          if (e is! Map<String, dynamic>) {
            throw Exception('Unexpected item type in list: ${e.runtimeType}');
          }
          return SessionCheckinToken.fromJson(e);
        })
        .toList(growable: false);
  }

  /// Mở token mới cho 1 session, TTL mặc định 180s
  static Future<SessionCheckinToken> openSessionCheckinToken({
    required String sessionId,
    int durationSeconds = 180,
  }) async {
    final resp = await ApiService.create(
      ApiConstants.sessionCheckinTokensOpen,
      {'session_id': sessionId, 'duration_seconds': durationSeconds},
    );

    // Backend có thể trả:
    // 1) { message, token: {...} }
    // 2) { ...token fields... }
    if (resp is Map<String, dynamic>) {
      final tokenField = resp['token'];
      if (tokenField is Map<String, dynamic>) {
        return SessionCheckinToken.fromJson(tokenField);
      }
      // Nếu không có "token", assume resp chính là token
      return SessionCheckinToken.fromJson(resp);
    }

    throw Exception(
      'Unexpected response when opening token: ${resp.runtimeType}',
    );
  }

  /// Đóng token (ngừng hiệu lực)
  static Future<void> closeSessionCheckinToken({
    required String sessionId,
  }) async {
    final resp = await ApiService.postExpectOk(
      ApiConstants.sessionCheckinTokensClose,
      {'session_id': sessionId},
    );

    // Nếu muốn, có thể verify resp == { ok: true } hoặc status code trong ApiService
    // Ở đây tin tưởng postExpectOk() đã throw nếu không 2xx.
    return;
  }

  /// Gia hạn thêm token (mặc định +120s)
  static Future<void> extendSessionCheckinToken({
    required String sessionId,
    int addSeconds = 120,
  }) async {
    await ApiService.postExpectOk(ApiConstants.sessionCheckinTokensExtend, {
      'session_id': sessionId,
      'add_seconds': addSeconds,
    });
  }
}
