import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Base URL for backend API.
  // Use Android emulator host (10.0.2.2) when running on Android emulators so the app
  // can reach the host machine's localhost. Otherwise use localhost.
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    final envUrl = dotenv.maybeGet('API_URL');

    final override = definedUrl.isNotEmpty
        ? definedUrl
        : (envUrl != null && envUrl.isNotEmpty ? envUrl : null);

    if (override != null) {
      return _normalizeBase(override);
    }

    final host = Platform.isAndroid ? '10.0.2.2:3000' : 'localhost:3000';
    return 'http://$host/api';
  }
  // Example: override with ngrok URL if needed: https://abc123.ngrok.io/api

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Student endpoints
  static const String students = '/students';

  // Teacher endpoints
  static const String teachers = '/teachers';

  // Attendance endpoints
  static const String attendance = '/attendance';
  static const String attendanceStats = '/attendance/stats';

  // Class endpoints
  static const String classes = '/classes';

  // Faculty endpoints
  static const String faculties = '/faculties';

  // Account endpoints
  static const String accounts = '/accounts';

  //Rooms endpoints
  static const String rooms = '/rooms';

  //Subjects endpoints
  static const String subjects = '/subjects';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static String _normalizeBase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final hasScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final withScheme = hasScheme ? trimmed : 'http://$trimmed';

    if (withScheme.endsWith('/api')) {
      return withScheme;
    }

    return withScheme.endsWith('/')
        ? '${withScheme}api'
        : '$withScheme/api';
  }
}
