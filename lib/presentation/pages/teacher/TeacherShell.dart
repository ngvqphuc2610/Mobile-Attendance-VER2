import 'package:flutter/material.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/presentation/pages/teacher/teacher_home_page.dart';
import 'package:mobile_attendance/data/services/auth_service.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});
  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;
  final _pages = const [
    TeacherHomePage(),
    _TeacherSchedulePage(),
    _TeacherQnaPage(),
    _TeacherNotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.face_retouching_natural),
            onPressed: () => Navigator.pushNamed(context, '/face_scan'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch dạy',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Hỏi đáp',
          ),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Thông báo'),
        ],
      ),
    );
  }
}

// Placeholder pages for teacher
class _TeacherSchedulePage extends StatelessWidget {
  const _TeacherSchedulePage();
  @override
  Widget build(BuildContext context) =>
      const _SimpleScaffold(title: 'Lịch dạy');
}

class _TeacherQnaPage extends StatelessWidget {
  const _TeacherQnaPage();
  @override
  Widget build(BuildContext context) => const _SimpleScaffold(title: 'Hỏi đáp');
}

class _TeacherNotificationsPage extends StatelessWidget {
  const _TeacherNotificationsPage();
  @override
  Widget build(BuildContext context) =>
      const _SimpleScaffold(title: 'Thông báo');
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
