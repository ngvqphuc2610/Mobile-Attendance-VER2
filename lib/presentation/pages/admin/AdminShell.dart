import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/di/dependency_injection.dart';
import '../../bloc/student/student_bloc.dart';
import '../../bloc/teacher/teacher_bloc.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../account_page.dart';
import 'AdminFaculties.dart';
import 'AdminStudents.dart';
import 'AdminTeachers.dart';
import 'AdminAccounts.dart';
import 'AdminClass.dart';
import 'AdminSubjects.dart';
import 'AdminRooms.dart';
import 'AdminEnrollments.dart';
import 'AdminSessionInstances.dart';
import 'AdminTeachingAssignments.dart';
import 'AdminSectionSchedules.dart';
import 'AdminSchedules.dart';
import 'AdminAttendance.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BlocProvider(
      create: (context) => sl<StudentBloc>(),
      child: const AdminStudents(),
    ),
    BlocProvider(
      create: (context) => sl<TeacherBloc>(),
      child: const AdminTeachers(),
    ),
    const AdminFaculties(),
    const AdminClasses(),
    BlocProvider(
      create: (context) => sl<AttendanceBloc>(),
      child: const AdminAttendance(),
    ),
    const AdminSubjects(),
    const AdminRooms(),
    const AdminEnrollments(),
    const AdminSessionInstances(),
    const AdminTeachingAssignments(),
    const AdminSectionSchedules(),
    const AdminSchedules(),
    const AccountsPage(),
    const AccountPage(),
  ];

  final List<String> _titles = [
    'Sinh viên',
    'Giảng viên',
    'Khoa',
    'Lớp',
    'Điểm danh',
    'Môn học',
    'Phòng học',
    'Đăng ký',
    'Buổi học',
    'Phân công',
    'Lịch học',
    'Thời khóa biểu',
    'Tài khoản',
    'Cá nhân',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Text(
                'Quản trị viên',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            _buildDrawerItem(Icons.school, 'Sinh viên', 0),
            _buildDrawerItem(Icons.person, 'Giảng viên', 1),
            _buildDrawerItem(Icons.business, 'Khoa', 2),
            _buildDrawerItem(Icons.class_, 'Lớp', 3),
            _buildDrawerItem(Icons.check_circle, 'Điểm danh', 4),
            _buildDrawerItem(Icons.book, 'Môn học', 5),
            _buildDrawerItem(Icons.room, 'Phòng học', 6),
            _buildDrawerItem(Icons.app_registration, 'Đăng ký', 7),
            _buildDrawerItem(Icons.event, 'Buổi học', 8),
            _buildDrawerItem(Icons.assignment_ind, 'Phân công', 9),
            _buildDrawerItem(Icons.schedule, 'Lịch học', 10),
            _buildDrawerItem(Icons.calendar_today, 'Thời khóa biểu', 11),
            const Divider(),
            _buildDrawerItem(Icons.account_circle, 'Tài khoản', 12),
            _buildDrawerItem(Icons.person_outline, 'Cá nhân', 13),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}

class _AdminHomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _AdminHomePage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.school,
        label: 'Khoa',
        index: 1,
        color: Colors.indigo,
      ),
      _QuickAction(
        icon: Icons.people,
        label: 'Sinh viên',
        index: 2,
        color: Colors.teal,
      ),
      _QuickAction(
        icon: Icons.person,
        label: 'Giáo viên',
        index: 3,
        color: Colors.deepPurple,
      ),
      _QuickAction(
        icon: Icons.analytics,
        label: 'Báo cáo',
        index: 4,
        color: Colors.orange,
      ),
      _QuickAction(
        icon: Icons.admin_panel_settings,
        label: 'QL Tài khoản',
        index: 5,
        color: Colors.blueGrey,
      ),
      _QuickAction(
        icon: Icons.account_circle,
        label: 'Tài khoản của tôi',
        index: 6,
        color: Colors.pink,
      ),
      _QuickAction(
        icon: Icons.class_,
        label: 'Lớp học',
        color: Colors.green,
        routeBuilder: (_) => const AdminClass(),
      ),
      _QuickAction(
        icon: Icons.subject,
        label: 'Môn học',
        color: Colors.amber,
        routeBuilder: (_) => const AdminSubject(),
      ),
      _QuickAction(
        icon: Icons.room,
        label: 'Phòng học',
        color: Colors.brown,
        routeBuilder: (_) => const AdminRoom(),
      ),
      _QuickAction(
        icon: Icons.assignment_ind,
        label: 'Đăng ký lớp',
        color: Colors.lime,
        routeBuilder: (_) => const AdminEnrollments(),
      ),
      _QuickAction(
        icon: Icons.schedule,
        label: 'Lịch học',
        color: Colors.cyan,
        routeBuilder: (_) => const AdminSchedules(),
      ),


      
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
              .map(
                (a) => _QuickActionCard(
                  action: a,
                  onTap: () {
                    if (a.index != null) {
                      onNavigate(
                        a.index!,
                      ); // chuyển tab cho các mục gắn BottomNav
                    } else if (a.routeBuilder != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: a.routeBuilder!,
                        ), // mở màn độc lập
                      );
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final int? index; // đi bằng BottomNavigationBar
  final WidgetBuilder? routeBuilder; // mở màn độc lập bằng push
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.index,
    this.routeBuilder,
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

