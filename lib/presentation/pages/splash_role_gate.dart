import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../core/constants/app_theme.dart';

class SplashRoleGatePage extends StatefulWidget {
  const SplashRoleGatePage({super.key});

  @override
  State<SplashRoleGatePage> createState() => _SplashRoleGatePageState();
}

class _SplashRoleGatePageState extends State<SplashRoleGatePage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Gợi ý: nếu bloc của bạn có event check token / me()
    // hãy bật dòng dưới (nếu không dùng thì bỏ qua)
    // context.read<AuthBloc>().add(AuthCheckRequested());
  }

  void _navigateByRole(dynamic roleOrRoles) {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Hỗ trợ cả string đơn lẫn List<String>
    bool has(String r) {
      if (roleOrRoles == null) return false;
      if (roleOrRoles is String) return roleOrRoles == r;
      if (roleOrRoles is List) return roleOrRoles.contains(r);
      return false;
    }

    if (has('admin')) {
      context.go('/admin');
    } else if (has('teacher')) {
      context.go('/teacher');
    } else {
      // mặc định student
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // UserModel currently exposes `role` as a String. Some backends
            // may return a JSON array or comma separated list inside that
            // field; try to handle these shapes and pass either a String or
            // a List<String> to the navigation helper.
            final rawRole = state.user.role;
            dynamic roleOrRoles;

            if (rawRole.trim().isEmpty) {
              roleOrRoles = null;
            } else {
              // Try parsing JSON array first
              try {
                final parsed = jsonDecode(rawRole);
                if (parsed is List) {
                  roleOrRoles = parsed.map((e) => e.toString()).toList();
                } else if (parsed is String) {
                  final s = parsed;
                  roleOrRoles = s.contains(',')
                      ? s.split(',').map((e) => e.trim()).toList()
                      : s;
                } else {
                  roleOrRoles = rawRole.toString();
                }
              } catch (_) {
                // Not JSON: support comma-separated values
                final s = rawRole.toString();
                roleOrRoles = s.contains(',')
                    ? s.split(',').map((e) => e.trim()).toList()
                    : s;
              }
            }

            _navigateByRole(roleOrRoles);
          } else if (state is AuthUnauthenticated) {
            if (!_navigated && mounted) {
              _navigated = true;
              context.go('/login');
            }
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                // Logo
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.school,
                    color: AppTheme.primaryColor,
                    size: 60,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Mobile Attendance',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hệ thống điểm danh thông minh',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 48),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
