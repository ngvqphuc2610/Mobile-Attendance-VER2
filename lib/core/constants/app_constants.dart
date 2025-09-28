class AppConstants {
  // App Info
  static const String appName = 'Mobile Attendance';
  static const String appVersion = '1.0.0';

  // Attendance Methods
  static const String attendanceMethodFace = 'face';
  static const String attendanceMethodBarcode = 'barcode';
  static const String attendanceMethodManual = 'manual';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleViewer = 'viewer';

  // Face Recognition
  static const double faceConfidenceThreshold = 0.8;
  static const int maxFaceEmbeddings = 5;

  // Database Tables
  static const String tableProfiles = 'profiles';
  static const String tableClasses = 'classes';
  static const String tableFaculties = 'faculties';
  static const String tableAttendance = 'attendance';
  static const String tableFaceEmbeddings = 'face_embeddings';
  static const String tableUserRoles = 'user_roles';
}
