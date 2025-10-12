import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_theme.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage();
  final _aOpts = const AndroidOptions(encryptedSharedPreferences: true);
  final _iOpts = const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null) {
        if (!mounted) return;
        await _secure.write(
          key: 'biometric_last',
          value: DateTime.now().toIso8601String(),
          aOptions: _aOpts,
          iOptions: _iOpts,
        );
        context.go('/splash');
      } else {
        setState(() => _error = 'Đăng nhập thất bại!');
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email hoặc mật khẩu không đúng!';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Email chưa được xác thực!';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Quá nhiều lần thử. Vui lòng đợi một chút!';
      } else {
        errorMessage = 'Lỗi đăng nhập: ${e.toString()}';
      }
      setState(() => _error = errorMessage);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        actions: [
          IconButton(
            tooltip: 'Đăng nhập bằng vân tay',
            icon: const Icon(Icons.fingerprint),
            onPressed: _loading ? null : _loginWithBiometric,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nhập email' : null,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty
                    ? 'Nhập mật khẩu'
                    : null,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _error = null);
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!isSupported || !canCheck) {
        setState(() => _error = 'Thiết bị không hỗ trợ sinh trắc học');
        return;
      }

      // Tìm tất cả user đã setup biometric
      final availableUsers = await _getAvailableBiometricUsers();
      
      if (availableUsers.isEmpty) {
        setState(() => _error = 'Chưa có tài khoản nào bật vân tay');
        return;
      }

      // Nếu có nhiều user, cho chọn
      String? selectedUserId;
      if (availableUsers.length == 1) {
        selectedUserId = availableUsers.first['userId'];
      } else {
        selectedUserId = await _showUserSelectionDialog(availableUsers);
      }

      if (selectedUserId == null) return;

      final ok = await _auth.authenticate(
        localizedReason: 'Xác thực để đăng nhập',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!ok) return;

      setState(() => _loading = true);

      // Thử refresh token trước
      final refreshToken = await _secure.read(
        key: 'refresh_token_$selectedUserId',
        aOptions: _aOpts,
        iOptions: _iOpts,
      );

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final authRes = await Supabase.instance.client.auth.setSession(refreshToken);
          if (authRes.session != null && mounted) {
            await _secure.write(
              key: 'biometric_last',
              value: DateTime.now().toIso8601String(),
              aOptions: _aOpts,
              iOptions: _iOpts,
            );
            context.go('/splash');
            return;
          }
        } catch (_) {
          // Token expired, fallback
        }
      }

      // Fallback: email/password
      final email = await _secure.read(
        key: 'biometric_email_$selectedUserId',
        aOptions: _aOpts,
        iOptions: _iOpts,
      );
      final password = await _secure.read(
        key: 'biometric_password_$selectedUserId',
        aOptions: _aOpts,
        iOptions: _iOpts,
      );
      
      if (email == null || password == null) {
        setState(() => _error = 'Thiếu thông tin đăng nhập cho user này');
        return;
      }

      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (response.user != null && mounted) {
          // Cập nhật token mới
          await _secure.write(
            key: 'refresh_token_$selectedUserId',
            value: response.session?.refreshToken ?? '',
            aOptions: _aOpts,
            iOptions: _iOpts,
          );
          await _secure.write(
            key: 'biometric_last',
            value: DateTime.now().toIso8601String(),
            aOptions: _aOpts,
            iOptions: _iOpts,
          );
          context.go('/splash');
        }
      } catch (e) {
        // Xử lý lỗi đăng nhập biometric
        if (e.toString().contains('Invalid login credentials')) {
          setState(() => _error = 'Thông tin đăng nhập vân tay đã hết hạn. Vui lòng đăng nhập lại và bật lại vân tay!');
          // Xóa thông tin biometric cũ
          await _secure.delete(key: 'biometric_enabled_$selectedUserId', aOptions: _aOpts, iOptions: _iOpts);
          await _secure.delete(key: 'refresh_token_$selectedUserId', aOptions: _aOpts, iOptions: _iOpts);
          await _secure.delete(key: 'biometric_email_$selectedUserId', aOptions: _aOpts, iOptions: _iOpts);
          await _secure.delete(key: 'biometric_password_$selectedUserId', aOptions: _aOpts, iOptions: _iOpts);
        } else {
          setState(() => _error = 'Lỗi đăng nhập vân tay: $e');
        }
      }
    } catch (e) {
      setState(() => _error = 'Lỗi đăng nhập: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, String>>> _getAvailableBiometricUsers() async {
    final users = <Map<String, String>>[];

    // Scan tất cả keys trong secure storage
    final allKeys = await _secure.readAll(aOptions: _aOpts, iOptions: _iOpts);

    for (final key in allKeys.keys) {
      if (key.startsWith('biometric_enabled_')) {
        final userId = key.replaceFirst('biometric_enabled_', '');
        final email = await _secure.read(
          key: 'biometric_email_$userId',
          aOptions: _aOpts,
          iOptions: _iOpts,
        );

        if (email != null) {
          users.add({'userId': userId, 'email': email});
        }
      }
    }

    return users;
  }

  Future<String?> _showUserSelectionDialog(
    List<Map<String, String>> users,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: users
              .map(
                (user) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user['email']!),
                  onTap: () => Navigator.pop(ctx, user['userId']),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}


