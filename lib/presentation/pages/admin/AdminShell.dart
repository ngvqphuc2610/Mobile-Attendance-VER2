import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/di/dependency_injection.dart';

// BLoC
import '../../bloc/account/account_event.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../bloc/class_section/class_section_event.dart';
import '../../bloc/enrollment/enrollment_event.dart';
import '../../bloc/faculty/faculty_event.dart';
import '../../bloc/section_schedule/section_schedule_event.dart';
import '../../bloc/session_instance/session_instance_event.dart';
import '../../bloc/student/student_event.dart';
import '../../bloc/subject/subject_event.dart';
import '../../bloc/teacher/teacher_event.dart';
import '../../bloc/teaching_assignment/teaching_assignment_event.dart';
import '../../bloc/account/account_bloc.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/class_section/class_section_bloc.dart';
import '../../bloc/enrollment/enrollment_bloc.dart';
import '../../bloc/faculty/faculty_bloc.dart';
import '../../bloc/section_schedule/section_schedule_bloc.dart';
import '../../bloc/session_instance/session_instance_bloc.dart';
import '../../bloc/student/student_bloc.dart';
import '../../bloc/subject/subject_bloc.dart';
import '../../bloc/teacher/teacher_bloc.dart';
import '../../bloc/teaching_assignment/teaching_assignment_bloc.dart';

// Pages
import 'AdminAccounts.dart';
import 'AdminAttendance.dart';
import 'AdminClasses.dart';
import 'AdminEnrollments.dart';
import 'AdminFaculties.dart';
import 'AdminRooms.dart';
import 'AdminSchedules.dart';
import 'AdminStudents.dart';
import 'AdminSubjects.dart';
import 'AdminTeachers.dart';
import 'AdminClassSection.dart';
import '../account_page.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final managementColumns = width >= 420 ? 3 : 2;
    final scheduleColumns = width >= 420 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        title: const Text(
          'Bảng điều khiển',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: AppSizes.paddingLarge),

              const _SectionHeader(title: 'Danh mục quản lý'),
              const SizedBox(height: AppSizes.paddingSmall),

              _ActionGrid(
                crossAxisCount: managementColumns,
                items: [
                  _ActionItem(
                    label: 'Sinh viên',
                    icon: Icons.school,
                    onTap: () => _openWithBloc<StudentBloc>(
                      context,
                      create: () => sl<StudentBloc>(),
                      page: (_) => const AdminStudents(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Giảng viên',
                    icon: Icons.person_outline,
                    onTap: () => _openWithBloc<TeacherBloc>(
                      context,
                      create: () => sl<TeacherBloc>(),
                      page: (_) => const AdminTeachers(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Khoa',
                    icon: Icons.apartment_outlined,
                    onTap: () => _openWithBloc<FacultyBloc>(
                      context,
                      create: () => sl<FacultyBloc>(),
                      page: (_) => const AdminFaculties(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Môn học',
                    icon: Icons.menu_book_outlined,
                    onTap: () => _openWithBloc<SubjectBloc>(
                      context,
                      create: () => sl<SubjectBloc>(),
                      page: (_) => const AdminSubjects(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Lớp học',
                    icon: Icons.class_,
                    onTap: () =>
                        _openSimple(context, (_) => const AdminClasses()),
                  ),
                  _ActionItem(
                    label: 'Phòng học',
                    icon: Icons.meeting_room_outlined,
                    onTap: () =>
                        _openSimple(context, (_) => const AdminRooms()),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              const _SectionHeader(title: 'Lịch & phân công'),
              const SizedBox(height: AppSizes.paddingSmall),

              _ActionGrid(
                crossAxisCount: scheduleColumns,
                items: [
                  _ActionItem(
                    label: 'Lịch giảng dạy',
                    icon: Icons.schedule_outlined,
                    onTap: () => _openWithMultiBloc(
                      context,
                      providers: [
                        BlocProvider(
                          create: (_) =>
                              sl<SectionScheduleBloc>()
                                ..add(const LoadSectionSchedules()),
                          lazy: false,
                        ),
                        BlocProvider(
                          create: (_) =>
                              sl<SessionInstanceBloc>()
                                ..add(const LoadSessionInstances()),
                          lazy: false,
                        ),
                        BlocProvider(
                          create: (_) =>
                              sl<TeachingAssignmentBloc>()
                                ..add(const LoadTeachingAssignments()),
                          lazy: false,
                        ),
                      ],
                      page: (_) => const AdminSchedules(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Lớp học phần',
                    icon: Icons.class_outlined,
                    onTap: () =>
                        _openSimple(context, (_) => const AdminClassSection()),
                  ),

                  _ActionItem(
                    label: 'Đăng ký học phần',
                    icon: Icons.how_to_reg_outlined,
                    onTap: () => _openWithMultiBloc(
                      context,
                      providers: [
                        BlocProvider(
                          create: (_) =>
                              sl<EnrollmentBloc>()
                                ..add(const LoadEnrollments()),
                          lazy: false,
                        ),
                        BlocProvider(
                          create: (_) =>
                              sl<ClassSectionBloc>()
                                ..add(const LoadClassSections()),
                          lazy: false,
                        ),
                        BlocProvider(
                          create: (_) =>
                              sl<StudentBloc>()..add(const LoadStudents()),
                          lazy: false,
                        ),
                      ],
                      page: (_) => const AdminEnrollments(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Điểm danh',
                    icon: Icons.check_circle_outline,
                    onTap: () => _openWithBloc<AttendanceBloc>(
                      context,
                      create: () => sl<AttendanceBloc>(),
                      page: (_) => const AdminAttendance(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Tài khoản',
                    icon: Icons.manage_accounts_outlined,
                    onTap: () => _openWithBloc<AccountBloc>(
                      context,
                      create: () => sl<AccountBloc>(),
                      page: (_) => const AdminAccounts(),
                    ),
                  ),
                  _ActionItem(
                    label: 'Cá nhân',
                    icon: Icons.person_outline,
                    onTap: () =>
                        _openSimple(context, (_) => const AccountPage()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm sinh viên, lớp học, ...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (_) {},
    );
  }

  /// MỞ TRANG ĐƠN GIẢN (không BLoC)
  static void _openSimple(
    BuildContext context,
    Widget Function(BuildContext) page,
  ) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => page(ctx)));
  }

  /// MỞ TRANG VỚI 1 BLoC - CHỈ tạo BLoC, page tự load data
  static void _openWithBloc<T extends BlocBase<Object?>>(
    BuildContext context, {
    required T Function() create,
    required Widget Function(BuildContext) page,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider<T>(
          create: (_) => create(),
          lazy: false, // ✅ Tạo BLoC ngay lập tức
          child: Builder(
            builder: (context) {
              // ✅ Context đã có BLoC, page có thể đọc ngay
              return page(context);
            },
          ),
        ),
      ),
    );
  }

  /// MỞ TRANG VỚI NHIỀU BLoC
  static void _openWithMultiBloc(
    BuildContext context, {
    required List<BlocProvider> providers,
    required Widget Function(BuildContext) page,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MultiBlocProvider(
          providers: providers, // ✅ giữ nguyên
          child: Builder(builder: (context) => page(context)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: .8,
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.items, required this.crossAxisCount});
  final List<_ActionItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (_, index) => _ActionTile(item: items[index]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});
  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2, // ✅ tránh tràn
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
