class ApiConstants {
  // Change this to your ngrok URL when available
  static const String baseUrl = 'http://localhost:3000/api';
  // Example: 'https://abc123.ngrok.io/api'
  
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
}
