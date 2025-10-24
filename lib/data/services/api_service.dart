import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/dto/user_model.dart';

class NeedTotpException implements Exception {
  final String message;
  const NeedTotpException([this.message = 'Mã xác thực hai bước cần thiết.']);

  @override
  String toString() => 'NeedTotpException: $message';
}

class ApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    if (_token != null) {
      return ApiConstants.getAuthHeaders(_token!);
    }
    return ApiConstants.headers;
  }

  // Auth methods
  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? totp,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        if (totp != null && totp.isNotEmpty) 'totp': totp,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data;
    }

    final error = _parseJsonSafe(response.body);
    if (response.statusCode == 403 &&
        error is Map &&
        (error['need_totp'] == true || error['need_totp'] == 'true')) {
      final message =
          (error['error'] ?? error['message'] ?? 'Yêu cầu mã xác thực hai bước')
              .toString();
      throw NeedTotpException(message);
    }

    final message = (error is Map && error['error'] != null)
        ? error['error'].toString()
        : 'Login failed';
    throw Exception(message);
  }

  static Future<Map<String, dynamic>> requestRegisterOtp(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerRequestOtp}'),
      headers: ApiConstants.headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final parsed = _parseJsonSafe(response.body);
      return Map<String, dynamic>.from(
        parsed is Map ? parsed : <String, dynamic>{},
      );
    }

    final error = _parseJsonSafe(response.body);
    final message = (error is Map && error['error'] != null)
        ? error['error'].toString()
        : 'Không thể gửi OTP';
    throw Exception(message);
  }

  static Future<Map<String, dynamic>> verifyRegisterOtp({
    required String transactionId,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerVerifyOtp}'),
      headers: ApiConstants.headers,
      body: jsonEncode({
        'transactionId': transactionId,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      return data;
    }

    final error = _parseJsonSafe(response.body);
    final message = (error is Map && error['error'] != null)
        ? error['error'].toString()
        : 'Xác thực OTP thất bại';
    throw Exception(message);
  }

  static Future<UserModel> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Failed to get current user');
    }
  }

  static Future<void> logout() async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
      headers: _headers,
    );
    clearToken();
  }

  static Future<Map<String, dynamic>> initTotp() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.totpInit}');
    final response = await http.post(url, headers: _headers);
    if (response.statusCode == 200) {
      final parsed = _parseJsonSafe(response.body);
      return Map<String, dynamic>.from(
        parsed is Map ? parsed : <String, dynamic>{},
      );
    }
    _extractError(response);
  }

  static Future<void> enableTotp({
    required String secret,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.totpEnable}');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'secret': secret, 'token': token}),
    );
    if (response.statusCode == 200) {
      return;
    }
    _extractError(response);
  }

  static Future<void> disableTotp(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.totpDisable}');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode == 200) {
      return;
    }
    _extractError(response);
  }

  static Future<void> verifyTotp(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.totpVerify}');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode == 200) {
      return;
    }
    _extractError(response);
  }

  // Generic CRUD methods
  static Future<List<Map<String, dynamic>>> getList(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch data');
    }
  }

  static Future<Map<String, dynamic>> create(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create');
    }
  }

  // Get single resource
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch resource');
    }
  }

  // Backwards-compatible: get by id
  static Future<Map<String, dynamic>> getById(
    String endpoint,
    String id,
  ) async {
    return get('$endpoint/$id');
  }

  // Allow get with query params for endpoints that return single-map responses
  static Future<Map<String, dynamic>> getWithParams(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null) uri = uri.replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch resource');
    }
  }

  static Future<Map<String, dynamic>> update(
    String endpoint,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update');
    }
  }

  // Convenience: update by full path (e.g. '/classes/123')
  static Future<Map<String, dynamic>> updateByPath(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to delete');
    }
  }

  // Convenience: delete by full path (e.g. '/classes/123')
  static Future<Map<String, dynamic>> deleteByPath(String path) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to delete');
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    String id,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}$endpoint/$id/$action'),
      headers: _headers,
      body: data != null ? jsonEncode(data) : null,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update');
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create');
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update');
    }
  }

  static dynamic _parseJsonSafe(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static Never _extractError(http.Response resp) {
    final parsed = _parseJsonSafe(resp.body);
    final msg = (parsed is Map && parsed['error'] != null)
        ? parsed['error'].toString()
        : 'Request failed with ${resp.statusCode}';
    throw Exception(msg);
  }
  
  static Future<dynamic> _requestExpect({
    required Future<http.Response> future,
    Set<int> ok = const {200},
  }) async {
    final resp = await future;
    if (ok.contains(resp.statusCode)) {
      final parsed = _parseJsonSafe(resp.body);
      // Nếu body rỗng thì trả {} để tránh lỗi cast
      return parsed ?? <String, dynamic>{};
    }
    _extractError(resp); // throws
  }

  static Future<Map<String, dynamic>> postExpectOk(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final resp = await _requestExpect(
      future: http.post(url, headers: _headers, body: jsonEncode(data)),
      ok: const {200, 201, 204},
    );
    // Nếu body rỗng -> trả {}
    return Map<String, dynamic>.from(resp is Map ? resp : <String, dynamic>{});
  }
}
