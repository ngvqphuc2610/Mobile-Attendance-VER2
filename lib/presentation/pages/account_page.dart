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
  static const AndroidOptions _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);
  static const IOSOptions _iosOptions = IOSOptions();

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    try {
      final canAuth = await BiometricAuth.canAuthenticate();
      final currentUser = await AuthService.getCurrentUser();

      setState(() {
        _biometricAvailable = canAuth;
      });

      if (canAuth && currentUser != null) {
        final enabled = await BiometricAuth.isEnabled(currentUser.id);
        setState(() {
          _biometricEnabled = enabled;
        });
      }
    } catch (e) {
      debugPrint('load biometric error: $e');
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
      if (currentUser == null) return;

      final authed = await BiometricAuth.authenticate(
        reason: 'Xac thuc van tay de bat dang nhap nhanh',
      );
      if (!authed) return;

      final password = await _promptPassword();
      if (password == null) return;

      await AuthService.login(currentUser.email, password);

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
      setState(() => _biometricEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da bat dang nhap van tay')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi: $e')),
      );
    }
  }

  Future<void> _disableBiometric() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) return;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Da tat dang nhap van tay')),
    );
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nhap mat khau'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mat khau hien tai',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui long nhap mat khau';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Xac nhan'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      return controller.text;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tai khoan'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Khong the tai thong tin nguoi dung'));
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
                              Text(user.email),
                              if (user.code != null && user.code.isNotEmpty)
                                Text('Ma: ${user.code}'),
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
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Thong tin ca nhan'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showComingSoonDialog(),
                      ),
                      if (_biometricAvailable) const Divider(height: 1),
                      if (_biometricAvailable)
                        SwitchListTile(
                          secondary: const Icon(Icons.fingerprint),
                          title: const Text('Dang nhap van tay'),
                          subtitle:
                              const Text('Su dung van tay de dang nhap nhanh'),
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Doi mat khau'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showComingSoonDialog(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Tro giup'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showComingSoonDialog(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                OutlinedButton.icon(
                  onPressed: () async {
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
                    'Dang xuat tai khoan',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sap ra mat'),
          content: const Text(
            'Tinh nang nay se duoc phat trien trong ban cap nhat tiep theo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Dong'),
            ),
          ],
        );
      },
    );
  }
}
