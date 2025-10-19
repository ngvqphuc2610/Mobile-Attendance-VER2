import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/enrollment_entity.dart';
import '../../../data/models/entity/class_section_entity.dart';
import '../../../data/models/entity/profile_entity.dart';
import '../../bloc/enrollment/enrollment_bloc.dart';
import '../../bloc/enrollment/enrollment_event.dart';
import '../../bloc/enrollment/enrollment_state.dart';
import '../../bloc/class_section/class_section_bloc.dart';
import '../../bloc/class_section/class_section_event.dart';
import '../../bloc/class_section/class_section_state.dart';
import '../../bloc/student/student_bloc.dart';
import '../../bloc/student/student_event.dart';
import '../../bloc/student/student_state.dart';
import '../../widgets/loading_widget.dart';

class AdminEnrollments extends StatefulWidget {
  const AdminEnrollments({super.key});

  @override
  State<AdminEnrollments> createState() => _AdminEnrollmentsState();
}

class _AdminEnrollmentsState extends State<AdminEnrollments> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<EnrollmentBloc>().add(const LoadEnrollments());
    context.read<ClassSectionBloc>().add(const LoadClassSections());
    context.read<StudentBloc>().add(const LoadStudents());
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
        title: const Text('Quản lý đăng ký học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<EnrollmentBloc, EnrollmentState>(
        listener: (context, state) {
          if (state is EnrollmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is EnrollmentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
                builder: (context, state) {
                  if (state is EnrollmentLoading) {
                    return const LoadingWidget(
                      message: 'Đang tải danh sách đăng ký...',
                    );
                  }

                  if (state is EnrollmentError) {
                    return _ErrorRetry(
                      message: state.message,
                      onRetry: () {
                        context.read<EnrollmentBloc>().add(
                          const LoadEnrollments(),
                        );
                      },
                    );
                  }

                  if (state is EnrollmentsLoaded) {
                    if (state.filteredEnrollments.isEmpty) {
                      return const Center(child: Text('Chưa có đăng ký nào'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: state.filteredEnrollments.length,
                      itemBuilder: (context, index) {
                        final enrollment = state.filteredEnrollments[index];
                        return _EnrollmentCard(
                          enrollment: enrollment,
                          onDelete: () => _showDeleteDialog(enrollment),
                        );
                      },
                    );
                  }

                  return const Center(child: Text('Không có dữ liệu'));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEnrollmentDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Tìm kiếm theo tên sinh viên hoặc lớp học phần...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        onChanged: (query) {
          context.read<EnrollmentBloc>().add(FilterEnrollments(query));
        },
      ),
    );
  }

  void _showEnrollmentDialog() {
    showDialog(
      context: context,
      builder: (context) => const _EnrollmentDialog(),
    );
  }

  void _showDeleteDialog(EnrollmentEntity enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa đăng ký này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<EnrollmentBloc>().add(
                DeleteEnrollment(
                  enrollment.id!,
                  enrollment.sectionId,
                  enrollment.studentId,
                ),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final EnrollmentEntity enrollment;
  final VoidCallback onDelete;

  const _EnrollmentCard({required this.enrollment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.school, color: Colors.white),
        ),
        title: Text(
          enrollment.student?.fullName ?? 'Không xác định',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lớp học phần: ${enrollment.section?.sectionCode ?? "N/A"}'),
            if (enrollment.section?.subject != null)
              Text('Môn học: ${enrollment.section!.subject!.name}'),
            Text(
              'Học kỳ: ${enrollment.section?.semester}/${enrollment.section?.year}',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EnrollmentDialog extends StatefulWidget {
  const _EnrollmentDialog();

  @override
  State<_EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<_EnrollmentDialog> {
  String? _selectedSectionId;
  String? _selectedStudentId;
  bool _isLoading = false;

  void _submit() {
    if (_selectedSectionId == null || _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    context.read<EnrollmentBloc>().add(
      CreateEnrollment(
        enrollmentId: UniqueKey().toString(),
        sectionId: _selectedSectionId!,
        studentId: _selectedStudentId!,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm đăng ký học mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<ClassSectionBloc, ClassSectionState>(
            builder: (context, state) {
              if (state is ClassSectionsLoaded) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Lớp học phần *',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSectionId,
                  items: state.filteredSections.map((section) {
                    return DropdownMenuItem(
                      value: section.id,
                      child: Text(
                        '${section.sectionCode} - ${section.subject?.name ?? "N/A"}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSectionId = value);
                  },
                );
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          BlocBuilder<StudentBloc, StudentState>(
            builder: (context, state) {
              if (state is StudentsLoaded) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sinh viên *',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedStudentId,
                  items: state.students.map((student) {
                    return DropdownMenuItem(
                      value: student.profileId,
                      child: Text(
                        '${student.profile?.fullName ?? "N/A"} (${student.mssv ?? "N/A"})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStudentId = value);
                  },
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
