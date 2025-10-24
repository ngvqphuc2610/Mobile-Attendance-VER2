import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_theme.dart';
import '../../core/di/dependency_injection.dart';
import '../../domain/usecases/auth/disable_totp_usecase.dart';
import '../../domain/usecases/auth/enable_totp_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth/auth_bloc.dart';
import '../dialogs/coming_soon_dialog.dart';
import '../dialogs/totp_code_dialog.dart';
import '../widgets/account/account_totp_card.dart';
import '../widgets/account/logout_button.dart';
import '../widgets/account/settings_menu_card.dart';
import '../widgets/account/user_profile_card.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;
  bool _totpEnabled = false;
  bool _totpBusy = false;
  bool _phoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadTotpState();
  }

  Future<void> _loadBiometricState() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final enabled = await _secure.read(
        key: 'biometric_enabled',
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled == 'true';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
          _biometricEnabled = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTotpState() async {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      setState(() {
        _totpEnabled = state.user.totpEnabled;
        _phoneVerified = state.user.phoneVerified;
      });
    }
  }

  Future<void> _toggleBiometric(bool? value) async {
    if (value == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (value) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Xác thực để bật đăng nhập vân tay',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (authenticated) {
          await _secure.write(
            key: 'biometric_enabled',
            value: 'true',
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );
          _showSuccess('Đã bật đăng nhập vân tay');
        } else {
          _showError('Xác thực thất bại');
          return;
        }
      } else {
        await _secure.delete(
          key: 'biometric_enabled',
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
        _showSuccess('Đã tắt đăng nhập vân tay');
      }

      setState(() => _biometricEnabled = value);
    } catch (e) {
      _showError('Có lỗi xảy ra: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTotp() async {
    if (_totpBusy) return;

    setState(() => _totpBusy = true);

    try {
      if (_totpEnabled) {
        await _disableTotp();
      } else {
        await _enableTotp();
      }
    } finally {
      setState(() => _totpBusy = false);
    }
  }

  Future<void> _enableTotp() async {
    try {
      final enableUsecase = sl<EnableTotpUsecase>();
      final setupResult = await enableUsecase.call();

      if (!mounted) return;

      if (setupResult.isFailure) {
        _showError('Không thể khởi tạo TOTP: ${setupResult.error}');
        return;
      }

      final setup = setupResult.data;
      if (setup == null) {
        _showError('Không thể lấy thông tin TOTP');
        return;
      }

      final totpCode = await TotpCodeDialog.show(
        context: context,
        title: 'Bật xác thực 2 bước',
        message:
            'Quét mã QR bằng ứng dụng Google Authenticator và nhập mã 6 số:\n\n⚠️ Lưu ý: Nếu tắt dialog, bạn phải quét lại từ đầu!',
        qrCodeImage: setup.qrDataUrl,
      );

      if (totpCode != null && totpCode.isNotEmpty) {
        // Verify TOTP code with backend
        final verifyResult = await enableUsecase.verify(
          secret: setup.secret,
          token: totpCode,
        );

        if (!mounted) return;

        if (verifyResult.isFailure) {
          _showError('Mã xác thực không chính xác: ${verifyResult.error}');
          return;
        }

        setState(() => _totpEnabled = true);
        _showSuccess('Đã bật xác thực 2 bước thành công');
        context.read<AuthBloc>().add(AuthRefreshRequested());
      }
    } catch (e) {
      _showError('Không thể bật xác thực 2 bước: ${e.toString()}');
    }
  }

  Future<void> _disableTotp() async {
    try {
      final code = await TotpCodeDialog.show(
        context: context,
        title: 'Tắt xác thực 2 bước',
        message: 'Nhập mã xác thực để tắt:',
      );

      if (code != null) {
        final usecase = sl<DisableTotpUsecase>();
        await usecase.call(code);

        setState(() => _totpEnabled = false);
        _showSuccess('Đã tắt xác thực 2 bước');
        if (mounted) {
          context.read<AuthBloc>().add(AuthRefreshRequested());
        }
      }
    } catch (e) {
      _showError('Không thể tắt xác thực 2 bước: ${e.toString()}');
    }
  }

  Future<void> _handleLogout() async {
    await _secure.delete(
      key: 'biometric_last',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    if (!mounted) return;
    context.read<AuthBloc>().add(AuthLogoutRequested());
    context.go('/login');
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

          final userModel = state.user;
          final user = UserEntity(
            id: userModel.id,
            email: userModel.email,
            fullName: userModel.fullName,
            code: userModel.code,
            role: userModel.role,
            phone: userModel.phone,
            isActive: userModel.isActive,
            createdAt: userModel.createdAt,
            phoneVerified: userModel.phoneVerified,
            totpEnabled: userModel.totpEnabled,
          );

          return RefreshIndicator(
            onRefresh: _loadBiometricState,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              children: [
                UserProfileCard(user: user),
                const SizedBox(height: AppSizes.paddingMedium),
                AccountTotpCard(
                  totpEnabled: _totpEnabled,
                  totpBusy: _totpBusy,
                  phoneVerified: _phoneVerified,
                  phone: user.phone,
                  onToggle: _toggleTotp,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                SettingsMenuCard(
                  biometricAvailable: _biometricAvailable,
                  isLoading: _isLoading,
                  biometricEnabled: _biometricEnabled,
                  onBiometricToggle: _toggleBiometric,
                  onPersonalInfo: () => ComingSoonDialog.show(context),
                  onChangePassword: () => ComingSoonDialog.show(context),
                  onHelp: () => ComingSoonDialog.show(context),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                LogoutButton(onLogout: _handleLogout),
              ],
            ),
          );
        },
      ),
    );
  }
}
