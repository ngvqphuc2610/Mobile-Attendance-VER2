import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/di/dependency_injection.dart';
import '../../bloc/auth/auth_bloc.dart' as auth;
import '../../bloc/enrollment/enrollment_bloc.dart';
import '../account_page.dart';
import 'StudentCheckinPage.dart';
import 'StudentListClassPage.dart';
import 'StudentSchedulePage.dart';
import 'student_home_page.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_StudentShellState>();
    state?._setIndex(index);
  }
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  final GlobalKey<StudentHomePageState> _homeKey =
      GlobalKey<StudentHomePageState>();
  final GlobalKey<StudentListClassPageState> _classesKey =
      GlobalKey<StudentListClassPageState>();
  final GlobalKey<StudentSchedulePageState> _scheduleKey =
      GlobalKey<StudentSchedulePageState>();

  String? _cachedStudentId;
  List<Widget>? _cachedPages;

  void _setIndex(int index) {
    final length = _cachedPages?.length ?? 1;
    final maxIndex = length > 0 ? length - 1 : 0;
    final next = index.clamp(0, maxIndex).toInt();
    if (next != _currentIndex && mounted) {
      setState(() => _currentIndex = next);
    }
  }

  void _handleTabRetap(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.scrollToTop();
        break;
      case 1:
        _classesKey.currentState?.scrollToTop();
        break;
      case 2:
        _scheduleKey.currentState?.scrollToTop();
        break;
      default:
        break;
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) {
      _handleTabRetap(index);
      return;
    }
    _setIndex(index);
  }

  List<Widget> _ensurePages(String studentId) {
    if (_cachedPages == null || _cachedStudentId != studentId) {
      _cachedStudentId = studentId;
      _cachedPages = [
        StudentHomePage(
          key: _homeKey,
          studentId: studentId,
          onNavigateToTab: _setIndex,
        ),
        BlocProvider<EnrollmentBloc>(
          create: (_) => sl<EnrollmentBloc>(),
          child: StudentListClassPage(key: _classesKey, studentId: studentId),
        ),
        StudentSchedulePage(key: _scheduleKey, studentId: studentId),
        StudentCheckinPage(studentId: studentId),
        const _NotificationsPage(),
        const AccountPage(),
      ];
    }
    return _cachedPages!;
  }

  void _resetPages() {
    _cachedPages = null;
    _cachedStudentId = null;
    if (mounted) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<auth.AuthBloc, auth.AuthState>(
      builder: (context, state) {
        // 1) Loading / Initial
        if (state is auth.AuthLoading || state is auth.AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) Authenticated
        if (state is auth.AuthAuthenticated) {
          final studentId = state.user.id;
          final pages = _ensurePages(studentId);
          final safeIndex = _currentIndex.clamp(0, pages.length - 1).toInt();

          return WillPopScope(
            onWillPop: () async {
              if (safeIndex != 0) {
                _setIndex(0);
                return false;
              }
              return true;
            },
            child: Scaffold(
              body: IndexedStack(index: safeIndex, children: pages),
              bottomNavigationBar: NavigationBar(
                selectedIndex: safeIndex,
                onDestinationSelected: _onDestinationSelected,
                height: 65,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.class_outlined),
                    selectedIcon: Icon(Icons.class_),
                    label: 'Lớp học',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.schedule_outlined),
                    selectedIcon: Icon(Icons.schedule),
                    label: 'TKB',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.qr_code_scanner_outlined),
                    selectedIcon: Icon(Icons.qr_code_scanner),
                    label: 'Điểm danh',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_outlined),
                    selectedIcon: Icon(Icons.notifications),
                    label: 'Thông báo',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_circle_outlined),
                    selectedIcon: Icon(Icons.account_circle),
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ),
          );
        }

        // 3) Error
        if (state is auth.AuthError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lỗi đăng nhập')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Colors.red,
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      'Đã xảy ra lỗi: ${state.message}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),
                    FilledButton(
                      onPressed: () {
                        _resetPages();
                        _setIndex(5);
                      },
                      child: const Text('Về trang Tài khoản'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 4) Unauthenticated
        _resetPages();
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Text(
                    'Vui lòng đăng nhập để sử dụng ứng dụng.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    title: 'Thông báo',
    message: 'Chưa có thông báo. Nội dung sẽ được cập nhật sau.',
  );
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderPage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
          ),
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
