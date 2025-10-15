import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../core/constants/app_theme.dart';
import '../../data/services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  
  final AndroidOptions _aOpts = const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final IOSOptions _iOpts = const IOSOptions();

  bool _biometric = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      setState(() {
        _biometricAvailable = isAvailable && isDeviceSupported;
      });

      if (_biometricAvailable) {
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null) {
          final enabled = await _secure.read(
            key: 'biometric_enabled_${currentUser.id}',
            aOptions: _aOpts,
            iOptions: _iOpts,
          );
          setState(() {
            _biometric = enabled == 'true';
          });
        }
      }
    } catch (e) {
      print('Error checking biometric: $e');
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
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để bật đăng nhập vân tay',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null) {
          // Save biometric settings
          await _secure.write(
            key: 'biometric_enabled_${currentUser.id}',
            value: 'true',
            aOptions: _aOpts,
            iOptions: _iOpts,
          );
          
          setState(() => _biometric = true);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã bật đăng nhập vân tay')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _disableBiometric() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) return;

    // Delete biometric data for current user
    await _secure.delete(
      key: 'biometric_enabled_${currentUser.id}',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.delete(
      key: 'refresh_token_${currentUser.id}',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.delete(
      key: 'biometric_email_${currentUser.id}',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );
    await _secure.delete(
      key: 'biometric_password_${currentUser.id}',
      aOptions: _aOpts,
      iOptions: _iOpts,
    );

    if (!mounted) return;
    setState(() => _biometric = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tắt đăng nhập vân tay')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(
              child: Text('Chưa đăng nhập'),
            );
          }

          final user = state.user;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              children: [
                // User info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.fullName.isNotEmpty 
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Settings card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Thông tin cá nhân'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showComingSoonDialog();
                        },
                      ),
                      const Divider(height: 1),
                      if (_biometricAvailable)
                        SwitchListTile(
                          secondary: const Icon(Icons.fingerprint),
                          title: const Text('Đăng nhập vân tay'),
                          subtitle: const Text('Sử dụng vân tay để đăng nhập nhanh'),
                          value: _biometric,
                          onChanged: _toggleBiometric,
                        ),
                      if (_biometricAvailable) const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Đổi mật khẩu'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showComingSoonDialog();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Trợ giúp'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showComingSoonDialog();
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingLarge),
                
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Clear biometric data
                      await _secure.delete(
                        key: 'biometric_last',
                        aOptions: _aOpts,
                        iOptions: _iOpts,
                      );
                      
                      // Logout
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
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

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sắp ra mắt'),
          content: const Text(
            'Tính năng này sẽ được phát triển trong phiên bản tiếp theo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}

