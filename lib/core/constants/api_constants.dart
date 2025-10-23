import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised API-related constants and helpers.
class ApiConstants {
  ApiConstants._();

  static final String baseUrl = _resolveBaseUrl();

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Core resources
  static const String accounts = '/accounts';
  static const String classes = '/classes';
  static const String faculties = '/faculties';
  static const String profiles = '/profiles';
  static const String rooms = '/rooms';
  static const String students = '/students';
  static const String subjects = '/subjects';
  static const String teachers = '/teachers';

  // Attendance and scheduling
  static const String attendance = '/attendance';
  static const String attendanceStats = '/attendance/stats';
  static const String enrollments = '/enrollments';
  static const String faceEmbeddings = '/face-embeddings';
  static const String sectionSchedules = '/section-schedules';
  static const String sessionInstances = '/session-instances';
  static const String teachingAssignments = '/teaching-assignments';
  static const String classSections = '/class-sections';
  static const String attendanceSessions = '/attendance-sessions';
  static const String schedules = '/schedules';
  // Session check-in tokens
  static const String sessionCheckinTokens       = '/session-checkin-tokens';        // GET list
  static const String sessionCheckinTokensOpen   = '/session-checkin-tokens/open';   // POST
  static const String sessionCheckinTokensClose  = '/session-checkin-tokens/close';  // POST
  static const String sessionCheckinTokensExtend = '/session-checkin-tokens/extend';

  static const String checkinPin = '/checkin/pin';
  static const String checkinQr = '/checkin/qr';
   // POST
  // Student schedules
  static const String studentSchedules = '/student-schedules';


  static String _resolveBaseUrl() {
    final raw = dotenv.env['API_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      return 'http://10.0.2.2:3000/api';
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
   }
}
