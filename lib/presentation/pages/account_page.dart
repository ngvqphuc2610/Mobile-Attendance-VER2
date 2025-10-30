import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_theme.dart';
import '../../core/services/biometric_auth.dart';
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
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        if (mounted) {
          setState(() {
            _biometricAvailable = false;
            _biometricEnabled = false;
            _isLoading = false;
          });
        }
        return;
      }

      final available = await BiometricAuth.canAuthenticate();
      final userId = authState.user.id;
      final storedAccount = await BiometricAuth.getAccount(userId);
      final enabled =
          storedAccount != null && await BiometricAuth.isEnabled(userId);

      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = available && enabled;
          _isLoading = false;
        });
      }
    } catch (_) {
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

    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) {
      _showError('Khong tim thay thong tin tai khoan hien tai.');
      return;
    }

    setState(() => _isLoading = true);

    final user = state.user;
    final userId = user.id;
    final lastKey = 'biometric_last_$userId';

    try {
      if (value) {
        final authenticated = await BiometricAuth.authenticate(
          reason: 'Xac thuc de bat dang nhap van tay',
        );

        if (!authenticated) {
          _showError('Xac thuc that bai');
          return;
        }

        final cachedJson = await _secure.read(
          key: lastKey,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );

        BiometricAccount? cachedAccount;
        if (cachedJson != null && cachedJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(cachedJson);
            if (decoded is Map<String, dynamic>) {
              final parsed = BiometricAccount.fromJson(decoded);
              if (parsed.password.isNotEmpty) {
                cachedAccount = parsed;
              }
            }
          } catch (_) {
            cachedAccount = null;
          }
        }

        if (cachedAccount == null) {
          _showError(
            'Khong tim thay mat khau gan nhat. Hay dang nhap lai bang email/mat khau roi thu lai.',
          );
          return;
        }

        final accountToSave = BiometricAccount(
          userId: userId,
          email: user.email,
          password: cachedAccount.password,
          fullName: user.fullName,
          role: user.role,
        );

        await BiometricAuth.saveAccount(accountToSave);
        await _secure.write(
          key: lastKey,
          value: jsonEncode(accountToSave.toJson()),
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
        _showSuccess('Da bat dang nhap van tay');
      } else {
        await BiometricAuth.deleteAccount(userId);
        _showSuccess('Da tat dang nhap van tay');
      }

      setState(() => _biometricEnabled = value);
    } catch (e) {
      _showError('Co loi xay ra: ${e.toString()}');
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
        _showError('Khong the khoi tao TOTP: ${setupResult.error}');
        return;
      }

      final setup = setupResult.data;
      if (setup == null) {
        _showError('Khong the lay thong tin TOTP');
        return;
      }

      final totpCode = await TotpCodeDialog.show(
        context: context,
        title: 'Bat xac thuc 2 buoc',
        message:
            'Quet ma QR bang ung dung Google Authenticator va nhap ma 6 so.\n\nNeu dong hop thoai, ban can quet lai tu dau.',
        qrCodeImage: setup.qrDataUrl,
      );

      if (totpCode != null && totpCode.isNotEmpty) {
        final verifyResult = await enableUsecase.verify(
          secret: setup.secret,
          token: totpCode,
        );

        if (!mounted) return;

        if (verifyResult.isFailure) {
          _showError('Ma xac thuc khong chinh xac: ${verifyResult.error}');
          return;
        }

        setState(() => _totpEnabled = true);
        _showSuccess('Da bat xac thuc 2 buoc thanh cong');

        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<AuthBloc>().add(
            AuthUserUpdated(authState.user.copyWith(totpEnabled: true)),
          );
        }
      }
    } catch (e) {
      _showError('Khong the bat xac thuc 2 buoc: ${e.toString()}');
    }
  }

  Future<void> _disableTotp() async {
    try {
      final code = await TotpCodeDialog.show(
        context: context,
        title: 'Tat xac thuc 2 buoc',
        message: 'Nhap ma xac thuc de tat:',
      );

      if (code != null) {
        final usecase = sl<DisableTotpUsecase>();
        await usecase.call(code);

        setState(() => _totpEnabled = false);
        _showSuccess('Da tat xac thuc 2 buoc');

        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<AuthBloc>().add(
            AuthUserUpdated(authState.user.copyWith(totpEnabled: false)),
          );
        }
      }
    } catch (e) {
      _showError('Khong the tat xac thuc 2 buoc: ${e.toString()}');
    }
  }

  Future<void> _handleLogout() async {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      await _secure.delete(
        key: 'biometric_last_${state.user.id}',
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    }

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
