import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_theme.dart';
import '../bloc/student/student_bloc.dart';
import '../bloc/student/student_event.dart';
import '../bloc/student/student_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'add_student_page.dart';
import 'student_detail_page.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StudentBloc>().add(const LoadStudentsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.studentList),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStudentPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sinh viên...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                context.read<StudentBloc>().add(SearchStudentsEvent(query));
              },
            ),
          ),

          // Student list
          Expanded(
            child: BlocBuilder<StudentBloc, StudentState>(
              builder: (context, state) {
                switch (state.status) {
                  case StudentStatus.loading:
                    return const LoadingWidget();
                  case StudentStatus.error:
                    return AppErrorWidget(
                      message: state.errorMessage ?? AppStrings.unknownError,
                      onRetry: () {
                        context.read<StudentBloc>().add(
                          const LoadStudentsEvent(),
                        );
                      },
                    );
                  case StudentStatus.loaded:
                    if (state.filteredStudents.isEmpty) {
                      return const Center(
                        child: Text('Không có sinh viên nào'),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = state.filteredStudents[index];
                        final className =
                            state.classes
                                .where((c) => c.id == student.classId)
                                .firstOrNull
                                ?.name ??
                            'Chưa có lớp';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMedium,
                            vertical: AppSizes.paddingSmall,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: student.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              child: Text(
                                student.fullName.isNotEmpty
                                    ? student.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mã SV: ${student.code}'),
                                Text('Lớp: $className'),
                                if (!student.isActive)
                                  const Text(
                                    'Không hoạt động',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentDetailPage(
                                          studentId: student.id,
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'delete':
                                    _showDeleteDialog(
                                      context,
                                      student.id,
                                      student.fullName,
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: ListTile(
                                    leading: Icon(Icons.visibility),
                                    title: Text('Xem chi tiết'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StudentDetailPage(studentId: student.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String studentId,
    String studentName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sinh viên "$studentName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<StudentBloc>().add(DeleteStudentEvent(studentId));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
