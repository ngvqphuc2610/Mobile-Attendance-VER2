import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_theme.dart';
import '../../core/services/biometric_auth.dart';
import '../bloc/auth/auth_bloc.dart';
import '../widgets/BiometricLoginButton.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  List<BiometricAccount> _biometricAccounts = const [];
  BiometricAccount? _selectedBiometricAccount;

  String? _lastLoginPassword;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  @override
  void dispose() {
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
        const SnackBar(
          content: Text('Không tìm thấy tài khoản sinh trắc học.'),
        ),
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
        const SnackBar(content: Text('Xác thực sinh trắc học thất bại.')),
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
                'Chọn tài khoản',
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
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            try {
              // ✅ LOGIC MỚI: Không can thiệp vào biometric đã được bật trong AccountPage
              // Chỉ lưu/cập nhật nếu user CHỌN "Ghi nhớ đăng nhập"
              
              final userId = state.user.id;
              final alreadyEnabled = await BiometricAuth.isEnabled(userId);
              
              if (_rememberMe && (_lastLoginPassword?.isNotEmpty ?? false)) {
                // User tick "Ghi nhớ" → Lưu/cập nhật thông tin
                final account = BiometricAccount(
                  userId: userId,
                  email: state.user.email,
                  password: _lastLoginPassword!,
                  fullName: state.user.fullName,
                  role: state.user.role,
                );
                await BiometricAuth.saveAccount(account);
              } else if (!_rememberMe && !alreadyEnabled) {
                // User KHÔNG tick "Ghi nhớ" VÀ chưa bật biometric trong settings
                // → Không làm gì cả (giữ nguyên trạng thái)
                // ✅ QUAN TRỌNG: Không xóa nếu đã được bật trong AccountPage
              }
              // Nếu alreadyEnabled = true và không tick "Ghi nhớ"
              // → GIỮ NGUYÊN, không xóa
              
            } catch (e) {
              debugPrint('Biometric save error: $e');
              // Bỏ qua lỗi secure storage
            }
            
            if (!mounted) return;
            context.go('/splash');
          }
        },
        child: SafeArea(
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
              ],
            ),
          ),
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
          'Hệ thống điểm danh thông minh',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(
                r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
              ).hasMatch(value.trim())) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            obscureText: _obscurePassword,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: const Text('Ghi nhớ đăng nhập'),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildLoginButtons() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final canUseBiometric =
            _biometricAvailable && _selectedBiometricAccount != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nút đăng nhập chính
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            // Divider "hoặc"
            if (_biometricAccounts.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'hoặc',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 14),

              // Hàng nút vân tay + chip chọn tài khoản (nếu có nhiều)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BiometricLoginButton(
                    busy: _biometricBusy,
                    onPressed: (!canUseBiometric || _biometricBusy)
                        ? null
                        : _handleBiometricLogin,
                    tooltip: canUseBiometric
                        ? 'Đăng nhập bằng vân tay'
                        : 'Không khả dụng',
                    size: 56,
                  ),
                  if (_biometricAccounts.length > 1) ...[
                    const SizedBox(width: 12),
                    ActionChip(
                      avatar: const Icon(Icons.expand_more, size: 18),
                      label: Text(
                        _selectedBiometricAccount?.fullName.isNotEmpty == true
                            ? _selectedBiometricAccount!.fullName
                            : (_selectedBiometricAccount?.email ??
                                  'Chọn tài khoản'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: _showBiometricAccountPicker,
                    ),
                  ],
                ],
              ),
              
              // Hint text
              if (canUseBiometric) ...[
                const SizedBox(height: 12),
                Text(
                  'Chạm vào biểu tượng vân tay để đăng nhập nhanh',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        );
      },
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
            const Text('Nhập email để nhận link đặt lại mật khẩu:'),
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
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập email để tiếp tục'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(rootContext).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vui lòng liên hệ quản trị viên để được hỗ trợ đặt lại mật khẩu.',
                  ),
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