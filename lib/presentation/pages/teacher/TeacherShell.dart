import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../account_page.dart';
import 'teacher_home_page.dart';
import 'TeacherClassPage.dart'; // Đổi tên file cho thống nhất

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
  
  // Static method để navigate từ child pages
  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_TeacherShellState>();
    state?._onDestinationSelected(index);
  }
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;
  
  // PageController để tối ưu performance
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          physics: const NeverScrollableScrollPhysics(), // Tắt swipe gesture
          children: const [
            TeacherHomePage(),
            _TeacherSchedulePage(),
            TeacherClassesPage(),
            _TeacherNotificationsPage(),
            AccountPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: Colors.white,
        elevation: 3,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Lịch dạy',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
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
    );
  }
}

// ==================== Placeholder Pages ====================

class _TeacherSchedulePage extends StatelessWidget {
  const _TeacherSchedulePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Lịch dạy'),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Lịch dạy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tính năng đang được phát triển',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherNotificationsPage extends StatelessWidget {
  const _TeacherNotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Thông báo'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Đánh dấu đã đọc tất cả',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng sắp ra mắt'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có thông báo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các thông báo mới sẽ hiển thị tại đây',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}