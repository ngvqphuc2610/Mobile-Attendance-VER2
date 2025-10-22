import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth/auth_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/biometric_auth.dart';
import '../../data/services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const IOSOptions _iosOptions = IOSOptions();

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    setState(() => _isLoading = true);
    
    try {
      final canAuth = await BiometricAuth.canAuthenticate();
      final currentUser = await AuthService.getCurrentUser();

      var enabled = false;
      if (canAuth && currentUser != null) {
        // Chỉ kiểm tra flag enabled và account có tồn tại
        // KHÔNG yêu cầu xác thực lại
        final flagEnabled = await BiometricAuth.isEnabled(currentUser.id);
        
        if (flagEnabled) {
          final account = await BiometricAuth.getAccount(currentUser.id);
          
          if (account != null && 
              account.email.isNotEmpty && 
              account.password.isNotEmpty) {
            enabled = true;
          } else {
            // Cleanup nếu flag enabled nhưng không có account hợp lệ
            await BiometricAuth.setEnabled(currentUser.id, false);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _biometricAvailable = canAuth;
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('load biometric error: $e');
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      await _enableBiometric();
    } else {
      await _disableBiometric();
    }
  }

  Future<void> _enableBiometric() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        _showError('Không tìm thấy thông tin người dùng');
        return;
      }

      // Bước 1: Xác thực sinh trắc học
      final authed = await BiometricAuth.authenticate(
        reason: 'Xác thực vân tay để bật đăng nhập nhanh',
      );
      
      if (!authed) {
        _showError('Xác thực vân tay thất bại');
        return;
      }

      // Bước 2: Nhập mật khẩu để verify
      final password = await _promptPassword();
      if (password == null || password.isEmpty) return;

      // Hiển thị loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Bước 3: Verify mật khẩu với backend
      try {
        await AuthService.login(currentUser.email, password);
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Đóng loading
        _showError(_resolveLoginError(e));
        return;
      }

      // Bước 4: Lưu thông tin sinh trắc học
      await BiometricAuth.saveAccount(
        BiometricAccount(
          userId: currentUser.id,
          email: currentUser.email,
          password: password,
          fullName: currentUser.fullName,
          role: currentUser.role,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng loading
      
      setState(() => _biometricEnabled = true);
      
      _showSuccess('Đã bật đăng nhập vân tay thành công');
    } catch (e) {
      debugPrint('enable biometric error: $e');
      if (!mounted) return;
      _showError('Không thể bật đăng nhập vân tay: ${e.toString()}');
    }
  }

  Future<void> _disableBiometric() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) return;

    // Xác nhận trước khi tắt
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Bạn có chắc muốn tắt đăng nhập vân tay?\n\n'
          'Bạn sẽ cần nhập mật khẩu để đăng nhập lần sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tắt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Xóa tất cả thông tin liên quan
    await BiometricAuth.deleteAccount(currentUser.id);
    await _secure.delete(
      key: 'refresh_token_${currentUser.id}',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await _secure.delete(
      key: 'biometric_email_${currentUser.id}',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await _secure.delete(
      key: 'biometric_password_${currentUser.id}',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    if (!mounted) return;
    setState(() => _biometricEnabled = false);
    
    _showWarning('Đã tắt đăng nhập vân tay');
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureText = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Xác nhận mật khẩu'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập mật khẩu hiện tại để xác nhận:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller,
                      obscureText: obscureText,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      return controller.text;
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! AuthAuthenticated) {
            return const Center(
              child: Text('Không thể tải thông tin người dùng'),
            );
          }

          final user = state.user;

          return RefreshIndicator(
            onRefresh: _loadBiometricState,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (user.code != null && user.code.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Mã: ${user.code}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Thông tin cá nhân'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showComingSoonDialog(),
                      ),
                      if (_biometricAvailable) const Divider(height: 1),
                      if (_biometricAvailable)
                        _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : SwitchListTile(
                                secondary: Icon(
                                  Icons.fingerprint,
                                  color: _biometricEnabled 
                                      ? AppColors.primary 
                                      : null,
                                ),
                                title: const Text('Đăng nhập vân tay'),
                                subtitle: Text(
                                  _biometricEnabled
                                      ? '✓ Đã bật - Sử dụng vân tay để đăng nhập nhanh'
                                      : 'Bật để đăng nhập nhanh hơn',
                                  style: TextStyle(
                                    color: _biometricEnabled
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                value: _biometricEnabled,
                                onChanged: _toggleBiometric,
                              ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Đổi mật khẩu'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showComingSoonDialog(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Trợ giúp'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showComingSoonDialog(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text(
                          'Bạn có chắc muốn đăng xuất?\n\n'
                          'Thông tin đăng nhập vân tay sẽ được giữ nguyên.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    // Không xóa thông tin biometric khi logout
                    await _secure.delete(
                      key: 'biometric_last',
                      aOptions: _androidOptions,
                      iOptions: _iosOptions,
                    );
                    if (!mounted) return;
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Đăng xuất tài khoản',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingSmall,
                    ),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _resolveLoginError(Object error) {
    final raw = error.toString().toLowerCase();
    
    // Xử lý các loại lỗi phổ biến
    if (raw.contains('invalid credential') || 
        raw.contains('invalid email or password') ||
        raw.contains('sai mat khau') ||
        raw.contains('wrong password')) {
      return 'Mật khẩu không đúng. Vui lòng thử lại.';
    }
    
    if (raw.contains('user not found') || raw.contains('account not found')) {
      return 'Tài khoản không tồn tại.';
    }
    
    if (raw.contains('network') || raw.contains('connection')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
    }
    
    if (raw.contains('timeout')) {
      return 'Quá thời gian chờ. Vui lòng thử lại.';
    }

    // Trích xuất message từ exception
    if (raw.contains('login failed:')) {
      final parts = raw.split('login failed:');
      if (parts.length > 1) {
        return parts.last
            .replaceAll('exception:', '')
            .replaceAll('error:', '')
            .trim();
      }
    }
    
    if (raw.contains('exception:')) {
      final parts = raw.split('exception:');
      if (parts.length > 1) {
        return parts.last.trim();
      }
    }
    
    return 'Không thể xác thực mật khẩu. Vui lòng thử lại.';
  }

  void _showComingSoonDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sắp ra mắt'),
          content: const Text(
            'Tính năng này sẽ được phát triển trong bản cập nhật tiếp theo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}