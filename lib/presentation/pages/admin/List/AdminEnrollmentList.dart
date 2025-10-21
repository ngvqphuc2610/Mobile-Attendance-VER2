import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/enrollment_entity.dart';
import '../../../bloc/enrollment/enrollment_bloc.dart';
import '../../../bloc/enrollment/enrollment_event.dart';
import '../../../bloc/enrollment/enrollment_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Edit/EditEnrollmentPage.dart';
import '../Add/AddEnrollmentPage.dart';

class AdminEnrollmentList extends StatefulWidget {
  const AdminEnrollmentList({super.key});

  @override
  State<AdminEnrollmentList> createState() => _AdminEnrollmentListState();
}

class _AdminEnrollmentListState extends State<AdminEnrollmentList> {
  // mở trang thêm
  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEnrollmentPage()),
    );
    if (created == true && mounted) {
      context.read<EnrollmentBloc>().add(const LoadEnrollments());
    }
  }

  // mở trang sửa
  Future<void> _openEdit(EnrollmentEntity enrollment) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditEnrollmentPage(
          // EditEnrollmentPage đang đọc 'section_id' và 'student_id'
          enrollment: {
            'id': enrollment.id,
            'section_id': enrollment.sectionId?.toString() ?? '',
            'student_id': enrollment.studentId?.toString() ?? '',
          },
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<EnrollmentBloc>().add(const LoadEnrollments());
    }
  }

  void _delete(EnrollmentEntity enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đăng ký này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              // Giữ nguyên event hiện tại của bạn
              context.read<EnrollmentBloc>().add(
                DeleteEnrollment(
                  enrollment.id!,           // nếu event mới không cần id, bạn có thể bỏ đi
                  enrollment.sectionId!,
                  enrollment.studentId!,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, state) {
        if (state is EnrollmentLoading) {
          return const LoadingWidget(message: 'Đang tải danh sách đăng ký...');
        }

        if (state is EnrollmentError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<EnrollmentBloc>().add(const LoadEnrollments()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is EnrollmentsLoaded) {
          final items = state.filteredEnrollments;
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có đăng ký nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                child: ListTile(
                  onTap: () => _openEdit(e), // 👈 chạm để sửa nhanh
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.school, color: Colors.white),
                  ),
                  title: Text(
                    e.student?.fullName ?? 'Không xác định',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lớp học phần: ${e.section?.sectionCode ?? "N/A"}'),
                      if (e.section?.subject != null)
                        Text('Môn học: ${e.section!.subject!.name}'),
                      Text('Học kỳ: ${e.section?.semester}/${e.section?.year}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _openEdit(e);
                          break;
                        case 'delete':
                          _delete(e);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Sửa'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text('Không có dữ liệu'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Stack để thêm FAB "Thêm"
    return Stack(
      children: [
        _buildBody(),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _openAdd,
            icon: const Icon(Icons.add),
            label: const Text('Thêm'),
          ),
        ),
      ],
    );
  }
}
