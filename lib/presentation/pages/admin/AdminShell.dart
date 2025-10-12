import 'package:flutter/material.dart';
import 'package:mobile_attendance/core/constants/app_theme.dart';
import 'package:mobile_attendance/presentation/pages/account_page.dart';
import 'AdminFaculties.dart';
import 'AdminStudent.dart';
import 'AdminTeacher.dart';
import 'AccountsPage.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _AdminHomePage(onNavigate: _go),
      const AdminFaculties(),
      const AdminStudent(),
      const AdminTeacher(),
      const _ReportsPage(),
      const AccountsPage(),
      const AccountPage(),
    ];
  }

  void _go(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Khoa'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sinh viên'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Giáo viên'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Quản lý tài khoản'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class _AdminHomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _AdminHomePage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(icon: Icons.school, label: 'Khoa', index: 1, color: Colors.indigo),
      _QuickAction(icon: Icons.people, label: 'Sinh viên', index: 2, color: Colors.teal),
      _QuickAction(icon: Icons.person, label: 'Giáo viên', index: 3, color: Colors.deepPurple),
      _QuickAction(icon: Icons.analytics, label: 'Báo cáo', index: 4, color: Colors.orange),
      _QuickAction(icon: Icons.admin_panel_settings, label: 'QL Tài khoản', index: 5, color: Colors.blueGrey),
      _QuickAction(icon: Icons.account_circle, label: 'Tài khoản của tôi', index: 6, color: Colors.pink),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Trang chủ')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSizes.paddingMedium,
          mainAxisSpacing: AppSizes.paddingMedium,
          children: actions
              .map((a) => _QuickActionCard(action: a, onTap: () => onNavigate(a.index)))
              .toList(),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final int index; // index của BottomNavigationBar
  final Color color;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.index,
    required this.color,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;
  const _QuickActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: action.color.withOpacity(0.15),
                child: Icon(action.icon, size: 28, color: action.color),
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage();
  @override
  Widget build(BuildContext context) =>
      const _Placeholder(title: 'Admin - Báo cáo');
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
