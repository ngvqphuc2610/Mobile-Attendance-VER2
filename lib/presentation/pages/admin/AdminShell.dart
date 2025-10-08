import 'package:flutter/material.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/presentation/pages/account_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    _AdminHomePage(),
    _ManageUsersPage(),
    _ReportsPage(),
    _SettingsPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_currentIndex >= 0 && _currentIndex < _pages.length)
        ? _currentIndex
        : 0;
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = safeIndex);
      });
    }
    return Scaffold(
      body: _pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        showUnselectedLabels: true,
        elevation: 8,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() {
          _currentIndex = index.clamp(0, _pages.length - 1);
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Quản trị'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class _AdminHomePage extends StatelessWidget {
  const _AdminHomePage();
  @override
  Widget build(BuildContext context) => const _Placeholder(title: 'Admin - Trang chủ');
}

class _ManageUsersPage extends StatelessWidget {
  const _ManageUsersPage();
  @override
  Widget build(BuildContext context) => const _Placeholder(title: 'Admin - Quản trị');
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage();
  @override
  Widget build(BuildContext context) => const _Placeholder(title: 'Admin - Báo cáo');
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();
  @override
  Widget build(BuildContext context) => const _Placeholder(title: 'Admin - Cài đặt');
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('TODO: Nội dung admin sẽ bổ sung sau')),
      backgroundColor: AppColors.background,
    );
  }
}
