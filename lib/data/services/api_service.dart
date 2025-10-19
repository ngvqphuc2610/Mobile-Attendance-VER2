import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/dto/user_model.dart';

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
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: ApiConstants.headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
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
}
