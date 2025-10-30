import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_theme.dart';
import '../../core/services/biometric_auth.dart';
import '../bloc/auth/auth_bloc.dart';
import '../widgets/BiometricLoginButton.dart';
import '../widgets/login/login_form_section.dart';
import '../widgets/login/login_buttons_section.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  bool _isTotpDialogVisible = false;
  List<BiometricAccount> _biometricAccounts = const [];
  BiometricAccount? _selectedBiometricAccount;

  String? _lastLoginPassword;
  bool _didNavigateAfterLogin = false;
  final TextEditingController _totpController = TextEditingController(text: '');
  bool _isSubmittingTotp = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  @override
  void dispose() {
    _didNavigateAfterLogin = true;
    _isTotpDialogVisible = false;
    _totpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================== Actions ==================
  void _login() {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    _lastLoginPassword = password;

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: password,
      ),
    );
  }

  Future<void> _initBiometric() async {
    try {
      final canAuth = await BiometricAuth.canAuthenticate();
      if (!canAuth) {
        if (!mounted) return;
        setState(() {
          _biometricAvailable = false;
          _biometricAccounts = const [];
          _selectedBiometricAccount = null;
        });
        return;
      }

      final accounts = await BiometricAuth.getAccounts();
      final sanitized = <BiometricAccount>[];
      final seenUserIds = <String>{};

      for (final account in accounts) {
        if (account.email.isEmpty || account.password.isEmpty) {
          await BiometricAuth.deleteAccount(account.userId);
          continue;
        }

        final enabled = await BiometricAuth.isEnabled(account.userId);
        if (!enabled) {
          await BiometricAuth.deleteAccount(account.userId);
          continue;
        }

        if (seenUserIds.add(account.userId)) {
          sanitized.add(account);
        }
      }

      if (!mounted) return;
      final previousSelectedId = _selectedBiometricAccount?.userId;
      setState(() {
        _biometricAccounts = List<BiometricAccount>.unmodifiable(sanitized);
        _selectedBiometricAccount = _biometricAccounts.isEmpty
            ? null
            : _biometricAccounts.firstWhere(
                (account) => account.userId == previousSelectedId,
                orElse: () => _biometricAccounts.first,
              );
        _biometricAvailable =
            canAuth &&
            _biometricAccounts.isNotEmpty &&
            _selectedBiometricAccount != null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
        _biometricAccounts = const [];
        _selectedBiometricAccount = null;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricAvailable || _selectedBiometricAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng nhập bằng vân tay.')),
      );
      return;
    }

    setState(() => _biometricBusy = true);

    final didAuthenticate = await BiometricAuth.authenticate(
      reason: 'Xác thực vân tay để đăng nhập',
    );
    if (!mounted) return;

    if (!didAuthenticate) {
      setState(() => _biometricBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác thực vân tay thất bại.')),
      );
      return;
    }

    final account = _selectedBiometricAccount!;
    _lastLoginPassword = account.password;
    _emailController.text = account.email;

    context.read<AuthBloc>().add(
      AuthLoginRequested(email: account.email, password: account.password),
    );

    setState(() => _biometricBusy = false);
  }

  Future<void> _showBiometricAccountPicker() async {
    if (_biometricAccounts.length <= 1) return;

    final chosen = await showModalBottomSheet<BiometricAccount>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Chọn tài khoản đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ..._biometricAccounts.map(
              (account) => ListTile(
                leading: const Icon(Icons.fingerprint),
                title: Text(
                  account.fullName.isNotEmpty
                      ? account.fullName
                      : account.email,
                ),
                subtitle: account.fullName.isNotEmpty
                    ? Text(account.email)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(account),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedBiometricAccount = chosen;
      });
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool isProcessing = _isSubmittingTotp || authState is AuthLoading;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            if (mounted) {
              setState(() {
                _isSubmittingTotp = false;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthLoginTotpRequired) {
            if (mounted) {
              setState(() {
                _isSubmittingTotp = false;
              });
            }
            if (!_isTotpDialogVisible) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _isTotpDialogVisible) return;
                _showTotpDialog(state);
              });
            }
          } else if (state is AuthAuthenticated) {
            if (mounted) {
              setState(() {
                _isSubmittingTotp = false;
              });
            }
            if (_didNavigateAfterLogin) return;
            try {
              // âœ… LOGIC Má»šI: KhÃ´ng can thiá»‡p vÃ o biometric Ä‘Ã£ Ä‘Æ°á»£c báº­t trong AccountPage
              // Chá»‰ lÆ°u/cáº­p nháº­t náº¿u user CHá»ŒN "Ghi nhá»› Ä‘Äƒng nháº­p"

              final userId = state.user.id;
              final alreadyEnabled = await BiometricAuth.isEnabled(userId);
              final passwordForCache =
                  (_lastLoginPassword != null && _lastLoginPassword!.isNotEmpty)
                  ? _lastLoginPassword!
                  : _passwordController.text;

              if (passwordForCache.isNotEmpty) {
                final cachedAccount = BiometricAccount(
                  userId: userId,
                  email: state.user.email,
                  password: passwordForCache,
                  fullName: state.user.fullName,
                  role: state.user.role,
                );
                await _secure.write(
                  key: 'biometric_last_' + userId,
                  value: jsonEncode(cachedAccount.toJson()),
                  aOptions: BiometricAuth.androidOptions,
                  iOptions: BiometricAuth.iosOptions,
                );
              }

              if (_rememberMe && passwordForCache.isNotEmpty) {
                final account = BiometricAccount(
                  userId: userId,
                  email: state.user.email,
                  password: passwordForCache,
                  fullName: state.user.fullName,
                  role: state.user.role,
                );
                await BiometricAuth.saveAccount(account);
              } else if (!_rememberMe && !alreadyEnabled) {
                // Giữ nguyên trạng thái, không xoá dữ liệu đã bật từ trang Tài khoản
              }
            } catch (e) {
              debugPrint('Biometric save error: $e');
              // Bỏ qua lỗi secure storage
            }

            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _didNavigateAfterLogin) return;
              _didNavigateAfterLogin = true;
              context.go('/splash');
            });
          }
        },
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildLogo(),
                    const SizedBox(height: 20),
                    _buildLoginForm(),
                    const SizedBox(height: 20),
                    _buildForgotPassword(),
                    const SizedBox(height: 20),
                    _buildLoginButtons(),
                    const SizedBox(height: 12),
                    _buildRegisterLink(),
                  ],
                ),
              ),
            ),
            if (isProcessing) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(60),
          ),
          child: const Icon(Icons.school, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mobile Attendance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Hệ thống quản lý sinh viên thông minh',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return LoginFormSection(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      onTogglePassword: (value) => setState(() => _obscurePassword = value),
      rememberMe: _rememberMe,
      onRememberMeChanged: (value) => setState(() => _rememberMe = value),
      onSubmit: _login,
    );
  }

  Widget _buildLoginButtons() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading || _isSubmittingTotp;
        final canUseBiometric =
            _biometricAvailable && _selectedBiometricAccount != null;

        return LoginButtonsSection(
          isLoading: isLoading,
          onLogin: _login,
          biometricAvailable: _biometricAvailable,
          biometricBusy: _biometricBusy,
          onBiometricPressed: canUseBiometric ? _handleBiometricLogin : null,
          biometricAccounts: _biometricAccounts,
          selectedAccount: _selectedBiometricAccount,
          onPickAccount: _showBiometricAccountPicker,
        );
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: const Text('Quên mật khẩu?'),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Chua co tai khoan?'),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Dang ky'),
        ),
      ],
    );
  }

  Future<void> _showTotpDialog(AuthLoginTotpRequired state) async {
    if (_isTotpDialogVisible) return;
    if (_didNavigateAfterLogin) return;
    setState(() => _isTotpDialogVisible = true);
    if (!mounted) return;
    _totpController
      ..text = ''
      ..selection = TextSelection.collapsed(offset: 0);
    final message = state.message;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nhập mã xác thực hai bước'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _totpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã xác thực',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = _totpController.text.trim();
                if (code.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập mã xác thực hợp lệ.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                _submitTotpCode(state, code);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      setState(() => _isTotpDialogVisible = false);
    }
  }

  void _submitTotpCode(AuthLoginTotpRequired state, String totp) {
    if (_isSubmittingTotp) return;
    setState(() {
      _isSubmittingTotp = true;
    });
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: state.email,
        password: state.password,
        totp: totp,
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang xác thực...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final rootContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập email của bạn để đặt lại mật khẩu.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập email.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(rootContext).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng kiểm tra email để đặt lại mật khẩu.'),
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}
