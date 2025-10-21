import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../bloc/teaching_assignment/teaching_assignment_bloc.dart';
import '../../../bloc/teaching_assignment/teaching_assignment_event.dart';
import '../../../bloc/teaching_assignment/teaching_assignment_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Edit/EditTeachingAssignmentPage.dart';
import '../Add/AddTeachingAssignmentPage.dart';

class AdminTeachingAssignmentList extends StatefulWidget {
  const AdminTeachingAssignmentList({Key? key}) : super(key: key);

  @override
  State<AdminTeachingAssignmentList> createState() =>
      _AdminTeachingAssignmentListState();
}

class _AdminTeachingAssignmentListState
    extends State<AdminTeachingAssignmentList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lọc danh sách
  void _filterAssignments(String query) {
    context.read<TeachingAssignmentBloc>().add(FilterTeachingAssignments(query));
  }

  // Xóa phân công
  void _deleteAssignment(Map<String, dynamic> ta) {
    final sectionId = ta['section_id']?.toString() ?? '';
    final teacherId = ta['teacher_id']?.toString() ?? '';
    context.read<TeachingAssignmentBloc>().add( DeleteTeachingAssignment('${Uri.encodeComponent(sectionId)}/${Uri.encodeComponent(teacherId)}'),);
  }

  // Mở trang chỉnh sửa
  Future<void> _showEditAssignmentPage(Map<String, dynamic> assignment) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTeachingAssignmentPage(assignment: assignment),
      ),
    );
    if (updated == true && mounted) {
      context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
    }
  }

  // Mở trang thêm mới
  Future<void> _showAddAssignmentPage() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTeachingAssignmentPage(),
      ),
    );
    if (created == true && mounted) {
      context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Thêm phân công'),
        backgroundColor: AppTheme.adminPrimaryColor,
        onPressed: _showAddAssignmentPage,
      ),
      body: BlocListener<TeachingAssignmentBloc, TeachingAssignmentState>(
        listener: (context, state) {
          if (state is TeachingAssignmentOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is TeachingAssignmentError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm theo lớp, giáo viên hoặc vai trò...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                onChanged: _filterAssignments,
              ),
            ),
            Expanded(
              child: BlocBuilder<TeachingAssignmentBloc, TeachingAssignmentState>(
                builder: (context, state) {
                  if (state is TeachingAssignmentLoading) {
                    return const LoadingWidget();
                  }

                  if (state is TeachingAssignmentError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(state.message),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context
                                .read<TeachingAssignmentBloc>()
                                .add(const LoadTeachingAssignments()),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is TeachingAssignmentsLoaded) {
                    final items = state.filteredAssignments;
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Không có phân công nào'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<TeachingAssignmentBloc>()
                            .add(const LoadTeachingAssignments());
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final ta = items[index];
                          final sectionName =
                              ta['section_name']?.toString() ?? '';
                          final teacherName =
                              ta['teacher_name']?.toString() ?? '';
                          final role = ta['role']?.toString() ?? '';
                          final subjectName =
                              ta['subject_name']?.toString() ?? '';

                          return ListTile(
                            leading: const Icon(Icons.school_outlined),
                            title: Text(
                              '$sectionName — $teacherName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (role.isNotEmpty)
                                  Text('Vai trò: $role'),
                                if (subjectName.isNotEmpty)
                                  Text('Môn: $subjectName'),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Chỉnh sửa',
                                  onPressed: () => _showEditAssignmentPage(ta),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Xóa',
                                  onPressed: () => _deleteAssignment(ta),
                                ),
                              ],
                            ),
                            onTap: () => _showEditAssignmentPage(ta),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
