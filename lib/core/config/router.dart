import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/admin/AdminShell.dart';
import '../../presentation/pages/attendance_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/splash_role_gate.dart';
import '../../presentation/pages/student/StudentShell.dart';
import '../../presentation/pages/teacher/TeacherShell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/splash', builder: (_, __) => const SplashRoleGatePage()),

    // Shells theo vai trò
    GoRoute(path: '/student', builder: (_, __) => const StudentShell()),
    GoRoute(path: '/teacher', builder: (_, __) => const TeacherShell()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),

    // Các trang lẻ
    GoRoute(path: '/attendance', builder: (_, __) => const AttendancePage()),
    // TODO: thêm các trang lẻ khác
  ],
  // Giảm log khi khởi tạo router trong build
  observers: const <NavigatorObserver>[],
  debugLogDiagnostics: false,
  navigatorKey: GlobalKey<NavigatorState>(),
);
