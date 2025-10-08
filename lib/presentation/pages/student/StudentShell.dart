import 'package:flutter/material.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/presentation/pages/student/student_home_page.dart';
import 'package:mobile_attendance/presentation/pages/account_page.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    StudentHomePage(),
    _TimetablePage(),
    _ExamSchedulePage(),
    _QnaPage(),
    _NotificationsPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_currentIndex >= 0 && _currentIndex < _pages.length)
        ? _currentIndex
        : 0;
    if (safeIndex != _currentIndex) {
      // Clamp to valid index in case items/pages changed
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
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'TKB'),
          BottomNavigationBarItem(icon: Icon(Icons.event_available), label: 'Lịch thi'),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer_outlined), label: 'Hỏi đáp'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

// Placeholder pages for student (TODO: replace with actual content)
class _TimetablePage extends StatelessWidget {
  const _TimetablePage();
  @override
  Widget build(BuildContext context) => const _SimpleScaffold(title: 'Thời khóa biểu');
}

class _ExamSchedulePage extends StatelessWidget {
  const _ExamSchedulePage();
  @override
  Widget build(BuildContext context) => const _SimpleScaffold(title: 'Lịch thi');
}

class _QnaPage extends StatelessWidget {
  const _QnaPage();
  @override
  Widget build(BuildContext context) => const _SimpleScaffold(title: 'Hỏi đáp');
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();
  @override
  Widget build(BuildContext context) => const _SimpleScaffold(title: 'Thông báo');
}

class _SimpleScaffold extends StatelessWidget {
  final String title;
  const _SimpleScaffold({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('TODO: Nội dung sẽ cập nhật sau')),
      backgroundColor: AppColors.background,
    );
  }
}
