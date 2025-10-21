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
  State<AdminTeachingAssignmentList> createState() => _AdminTeachingAssignmentListState();
}

class _AdminTeachingAssignmentListState extends State<AdminTeachingAssignmentList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAssignments(String query) {
    context.read<TeachingAssignmentBloc>().add(FilterTeachingAssignments(query));
  }

  void _deleteAssignment(Map<String, dynamic> ta) {
    final sectionId = ta['section_id']?.toString() ?? '';
    final teacherId = ta['teacher_id']?.toString() ?? '';
    context.read<TeachingAssignmentBloc>().add(DeleteTeachingAssignment('$sectionId|$teacherId'));
  }

  Future<void> _showEditAssignmentPage(Map<String, dynamic> assignment) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        // Edit page nhận Map thay vì model
        builder: (context) => EditTeachingAssignmentPage(assignment: assignment),
      ),
    );
    if (updated == true && mounted) {
      context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
    }
  }

  Future<void> _showAddAssignmentPage() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddTeachingAssignmentPage()),
    );
    if (created == true && mounted) {
      context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phân công giảng dạy'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddAssignmentPage),
        ],
      ),
      body: BlocListener<TeachingAssignmentBloc, TeachingAssignmentState>(
        listener: (context, state) {
          if (state is TeachingAssignmentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is TeachingAssignmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                  hintText: 'Tìm theo section, giáo viên hoặc vai trò...',
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
                          const Icon(Icons.error_outline),
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
                      return const Center(child: Text('Không có phân công nào'));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final ta = items[index];
                          final sectionId = ta['section_id']?.toString() ?? '';
                          final teacherId = ta['teacher_id']?.toString() ?? '';
                          final sectionName = ta['section_name']?.toString();
                          final teacherName = ta['teacher_name']?.toString();
                          final subjectName = ta['subject_name']?.toString();
                          final role = ta['role']?.toString();

                          return Dismissible(
                            key: ValueKey('$sectionId|$teacherId'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xoá phân công'),
                                      content: Text(
                                        'Xoá phân công của ${teacherName ?? 'GV $teacherId'} '
                                        'ở ${sectionName ?? 'Section $sectionId'}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Huỷ'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Xoá'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) => _deleteAssignment(ta),
                            child: ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(
                                '${sectionName ?? 'Section $sectionId'} — ${teacherName ?? 'GV $teacherId'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (role != null && role.isNotEmpty) Text('Vai trò: $role'),
                                  if (subjectName != null && subjectName.isNotEmpty)
                                    Text('Môn: $subjectName'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Chỉnh sửa',
                                onPressed: () => _showEditAssignmentPage(ta),
                              ),
                              onTap: () => _showEditAssignmentPage(ta),
                            ),
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
