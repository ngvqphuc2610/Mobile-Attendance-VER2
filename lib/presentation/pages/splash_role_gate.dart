import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';

class SplashRoleGatePage extends StatefulWidget {
  const SplashRoleGatePage({super.key});

  @override
  State<SplashRoleGatePage> createState() => _SplashRoleGatePageState();
}

class _SplashRoleGatePageState extends State<SplashRoleGatePage> {
  String? _unsupportedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthInitial) {
        authBloc.add(AuthCheckRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final targetRoute = _mapRoleToRoute(state.user.role);
            if (targetRoute != null) {
              context.go(targetRoute);
            } else {
              setState(() => _unsupportedRole = state.user.role);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            }
          } else if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          if (_unsupportedRole != null) {
            return _buildErrorView(
              title: 'Quyền truy cập không được hỗ trợ',
              message:
                  'Tài khoản của bạn có vai trò \"$_unsupportedRole\" và hiện chưa được hỗ trợ trong ứng dụng. '
                  'Vui lòng liên hệ quản trị viên để được cấp quyền phù hợp.',
              actionLabel: 'Quay lại đăng nhập',
              onAction: _handleLogout,
            );
          }

          if (state is AuthError) {
            return _buildErrorView(
              title: 'Không thể xác thực',
              message: state.message,
              actionLabel: 'Thử lại',
              onAction: _retryAuthCheck,
            );
          }

          return _buildLoadingView(
            message: state is AuthLoading
                ? 'Đang kiểm tra phiên đăng nhập...'
                : 'Đang chuẩn bị ứng dụng...',
          );
        },
      ),
    );
  }

  void _retryAuthCheck() {
    setState(() => _unsupportedRole = null);
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  void _handleLogout() {
    setState(() => _unsupportedRole = null);
    context.read<AuthBloc>().add(AuthLogoutRequested());
    context.go('/login');
  }

  String? _mapRoleToRoute(String? role) {
    if (role == null) return null;
    switch (role.toLowerCase()) {
      case AppConstants.roleStudent:
        return '/student';
      case AppConstants.roleTeacher:
        return '/teacher';
      case AppConstants.roleAdmin:
      case AppConstants.roleViewer:
        return '/admin';
      default:
        return null;
    }
  }

  Widget _buildLoadingView({required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: AppSizes.paddingLarge),
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: AppSizes.paddingLarge),
            Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.verified_user, size: 48, color: Colors.white),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        const Text(
          'Mobile Attendance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
