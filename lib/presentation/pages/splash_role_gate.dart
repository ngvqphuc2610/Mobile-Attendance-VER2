import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/helpers/role_helper.dart';

class SplashRoleGatePage extends StatefulWidget {
  const SplashRoleGatePage({super.key});

  @override
  State<SplashRoleGatePage> createState() => _SplashRoleGatePageState();
}

class _SplashRoleGatePageState extends State<SplashRoleGatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decide();
    });
  }

  Future<void> _decide() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (!mounted) return;
        context.go('/login');
        return;
      }
      // Biometric gate theo tuần nếu người dùng đã bật
      const aOpts = AndroidOptions(encryptedSharedPreferences: true);
      const iOpts = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
      final storage = const FlutterSecureStorage();
      final enabled = (await storage.read(key: 'biometric_enabled', aOptions: aOpts, iOptions: iOpts)) == 'true';
      if (enabled) {
        final lastStr = await storage.read(key: 'biometric_last', aOptions: aOpts, iOptions: iOpts);
        final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
        final needAuth = last == null || DateTime.now().difference(last) > const Duration(days: 7);
        if (needAuth) {
          final auth = LocalAuthentication();
          final ok = await auth.authenticate(
            localizedReason: 'Xác thực để vào ứng dụng',
            options: const AuthenticationOptions(biometricOnly: true),
          );
          if (!ok) {
            if (!mounted) return;
            context.go('/login');
            return;
          }
          await storage.write(
            key: 'biometric_last',
            value: DateTime.now().toIso8601String(),
            aOptions: aOpts,
            iOptions: iOpts,
          );
        }
      }

      final role = await fetchUserRole();
      if (!mounted) return;
      switch (role) {
        case AppRole.teacher:
          context.go('/teacher');
          break;
        case AppRole.admin:
          context.go('/admin');
          break;
        case AppRole.student:
        default:
          context.go('/student');
          break;
      }
    } catch (e) {
      // Nếu có lỗi (ví dụ RLS ngăn truy vấn), fallback về student
      if (!mounted) return;
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

