import 'package:flutter/material.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/presentation/pages/account_page.dart';
import 'package:mobile_attendance/presentation/pages/attendance_page.dart';
import 'package:mobile_attendance/presentation/pages/student_list_page.dart';
import 'package:mobile_attendance/presentation/pages/teacher/teacher_home_page.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    TeacherHomePage(),
    StudentListPage(),
    AttendancePage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sinh viên'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Điểm danh'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
