import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../core/constants/app_theme.dart';
import '../../data/models/dto/register_otp_result.dart';
import '../bloc/auth/auth_bloc.dart';
import '../widgets/register/register_form.dart';
import '../widgets/register/register_otp_step.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final smartAuth = SmartAuth.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isOtpStep = false;
  bool _isListeningSms = false;

  RegisterOtpResult? _otpResult;
  RegisterRequestData? _latestRequest;

  static const int _resendWindow = 60;
  Timer? _otpTimer;
  int _secondsRemaining = 0;
  int _resendCountdown = 0;

  String _role = 'student';

  @override
  void dispose() {
    _otpTimer?.cancel();
    _otpController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    smartAuth.removeSmsRetrieverApiListener();
    super.dispose();
  }

  void _startOtpCountdown(int ttl) {
    _otpTimer?.cancel();
    setState(() {
      _secondsRemaining = ttl;
      _resendCountdown = _resendWindow;
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
        if (_resendCountdown > 0) {
          _resendCountdown--;
        }
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _startSmsRetriever() async {
  if (_isListeningSms) return;
  setState(() => _isListeningSms = true);
  try {
    // Gọi API đúng của smart_auth
    final res = await smartAuth.getSmsWithRetrieverApi();
    if (!mounted) return;

    if (res.hasData) {
      // code có thể null nếu không trích xuất được từ SMS
      final code = res.requireData.code;
      if (code != null) {
        _otpController.text = code;
        _submitOtp(autoFilled: true);
      }
    } else {
      // có thể là timeout hoặc error – tùy bạn muốn hiển thị gì
      debugPrint('SMS retriever: ${res.error} | canceled=${res.isCanceled}');
    }
  } catch (e) {
    debugPrint('SMS retriever error: $e');
  } finally {
    if (mounted) setState(() => _isListeningSms = false);
  }
}


  String? _extractOtpFromMessage(String message) {
    final match = RegExp(r'\b\d{4,6}\b').firstMatch(message);
    return match?.group(0);
  }

  void _onRequestOtp() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final data = RegisterRequestData(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      code: _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      role: _role,
    );

    _latestRequest = data;
    context
        .read<AuthBloc>()
        .add(AuthRegisterOtpRequested(data: data));
  }

  void _submitOtp({bool autoFilled = false}) {
    final transactionId = _otpResult?.transactionId;
    if (transactionId == null) {
      _showSnackBar('Mã OTP đã hết hạn, vui lòng gửi lại.', color: Colors.red);
      return;
    }

    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      if (!autoFilled) {
        _showSnackBar('Vui lòng nhập mã OTP hợp lệ.', color: Colors.red);
      }
      return;
    }

    context.read<AuthBloc>().add(
          AuthRegisterOtpSubmitted(
            transactionId: transactionId,
            otp: otp,
          ),
        );
  }

  void _resendOtp() {
    if (_latestRequest == null) return;
    context
        .read<AuthBloc>()
        .add(AuthRegisterOtpRequested(data: _latestRequest!));
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthLoading) {
          setState(() => _isSubmitting = true);
          return;
        }

        setState(() => _isSubmitting = false);

        if (state is AuthError) {
          _showSnackBar(
            state.message.replaceFirst('Exception: ', ''),
            color: Colors.red,
          );
        } else if (state is AuthRegisterOtpSent) {
          setState(() {
            _otpResult = state.result;
            _latestRequest = state.result.requestData;
            _isOtpStep = true;
            _otpController.clear();
          });
          _startOtpCountdown(state.result.expiresIn);
          unawaited(_startSmsRetriever());
          final phone = _maskPhone(_latestRequest?.phone ?? '');
          _showSnackBar(
            'Đã gửi mã OTP tới $phone.',
            color: Colors.green,
          );
        } else if (state is AuthAuthenticated) {
          _otpTimer?.cancel();
          await smartAuth.removeSmsRetrieverApiListener();
          if (!mounted) return;
          _showSnackBar(
            'Đăng ký thành công! Đang chuyển hướng...',
            color: Colors.green,
          );
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) {
            context.go('/splash');
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Đăng ký tài khoản'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isOtpStep
                    ? RegisterOtpStep(
                        key: const ValueKey('otp-step'),
                        otpController: _otpController,
                        secondsRemaining: _secondsRemaining,
                        resendCountdown: _resendCountdown,
                        isSubmitting: _isSubmitting,
                        onSubmit: _submitOtp,
                        onResend: _resendOtp,
                        onBack: () {
                          setState(() {
                            _isOtpStep = false;
                            _otpResult = null;
                            _otpController.clear();
                          });
                        },
                        maskedPhone:
                            _maskPhone(_latestRequest?.phone ?? ''),
                      )
                    : RegisterForm(
                        key: const ValueKey('register-form'),
                        formKey: _formKey,
                        fullNameController: _fullNameController,
                        emailController: _emailController,
                        phoneController: _phoneController,
                        codeController: _codeController,
                        passwordController: _passwordController,
                        confirmPasswordController:
                            _confirmPasswordController,
                        role: _role,
                        onRoleChanged: (role) {
                          setState(() => _role = role);
                        },
                        onSubmit: _onRequestOtp,
                        onNavigateToLogin: () => context.go('/login'),
                        isSubmitting: _isSubmitting,
                        obscurePassword: _obscurePassword,
                        obscureConfirmPassword: _obscureConfirmPassword,
                        onTogglePasswordObscure: (value) {
                          setState(() => _obscurePassword = value);
                        },
                        onToggleConfirmPasswordObscure: (value) {
                          setState(() => _obscureConfirmPassword = value);
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return phone;
    final sanitized = phone.replaceAll(RegExp(r'\s'), '');
    if (sanitized.length < 4) return sanitized;
    final last = sanitized.substring(sanitized.length - 3);
    return '*** *** $last';
  }
}
