import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/student_entity.dart';
import '../../bloc/student/student_bloc.dart';
import '../../bloc/student/student_event.dart';
import '../../bloc/student/student_state.dart';

// Bạn nói đã import 2 trang này — giữ nguyên đường dẫn của bạn
import 'add/AddStudentPage.dart';
import 'edit/EditStudentPage.dart';

class AdminStudents extends StatefulWidget {
  const AdminStudents({super.key});

  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load sau frame đầu tiên để chắc chắn context đã có BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StudentBloc>().add(const LoadStudents());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<StudentBloc>().add(FilterStudents(query.trim()));
    });
  }

  // ---------- Điều hướng: Add & Edit ----------
  Future<void> _openAddStudent() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStudentPage()),
    );
    if (!mounted) return;
    if (created == true) {
      context.read<StudentBloc>().add(const LoadStudents());
    }
  }

  Future<void> _openEditStudent(StudentEntity student) async {
    final payload = {
      'profile_id': student.profileId,
      'code': student.profile?.code,
      'full_name': student.profile?.fullName,
      'email': student.profile?.email,
      'phone': student.profile?.phone,
      'class_id': student.classId,
      'mssv': student.mssv,
      'mssv_cohort': student.mssvCohort,
      'mssv_track_code': student.mssvTrackCode,
      'mssv_serial': student.mssvSerial,
    };

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentPage(student: payload),
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      context.read<StudentBloc>().add(const LoadStudents());
    }
  }

  // ---------- Xác nhận xóa ----------
  void _confirmDelete(StudentEntity student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sinh viên'),
        content: Text(
          'Bạn muốn xóa sinh viên "${student.profile?.fullName ?? student.profileId}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<StudentBloc>().add(DeleteStudent(student.profileId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // FAB thêm sinh viên
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStudent,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm sinh viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is StudentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is StudentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            // Trường hợp thao tác đến từ nơi khác, vẫn đảm bảo reload
            context.read<StudentBloc>().add(const LoadStudents());
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ép toàn bộ nội dung có width hữu hạn
              Widget wrap(Widget child) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: child,
                    ),
                  );

              // Header (search + add) dưới dạng Sliver
              SliverToBoxAdapter header() => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: 'Tìm theo MSSV, tên, mã sinh viên...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                                ),
                                filled: true,
                              ),
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          ElevatedButton.icon(
                            onPressed: _openAddStudent,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

              return BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentLoading) {
                    return wrap(
                      CustomScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: const [
                          SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is StudentError) {
                    return wrap(
                      CustomScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          header(),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: Text('Đã xảy ra lỗi. Thử lại nhé.')),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is StudentsLoaded) {
                    final items = state.filteredStudents;

                    // Rỗng
                    if (items.isEmpty) {
                      return wrap(
                        CustomScrollView(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            header(),
                            const SliverToBoxAdapter(child: SizedBox(height: 12)),
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      state.students.isEmpty ? Icons.people_outline : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.students.isEmpty
                                          ? 'Chưa có sinh viên nào'
                                          : 'Không tìm thấy kết quả',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    if (state.students.isEmpty)
                                      ElevatedButton.icon(
                                        onPressed: _openAddStudent,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm sinh viên đầu tiên'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Có dữ liệu
                    return wrap(
                      CustomScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          header(),
                          SliverList.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final s = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                                child: KeyedSubtree(
                                  key: ValueKey(s.profileId),
                                  child: _StudentCard(
                                    student: s,
                                    onEdit: () => _openEditStudent(s),
                                    onDelete: () => _confirmDelete(s),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ],
                      ),
                    );
                  }

                  // Initial
                  return wrap(
                    CustomScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        header(),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => context.read<StudentBloc>().add(const LoadStudents()),
                              icon: const Icon(Icons.download),
                              label: const Text('Tải danh sách sinh viên'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = student.profile;
    final name = (p?.fullName ?? '').trim();
    // Lấy ký tự Unicode đầu tiên an toàn
    final initials = name.isNotEmpty ? name.characters.first.toUpperCase() : 'S';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      elevation: 2,
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: p?.isActive == true ? AppColors.secondary : Colors.grey,
          child: Text(
            initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name.isNotEmpty ? name : 'Chưa có tên',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: p?.isActive == true ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (student.mssv?.isNotEmpty == true)
              Text('MSSV: ${student.mssv}', style: const TextStyle(fontSize: 12)),
            if (p?.code?.isNotEmpty == true)
              Text('Mã SV: ${p!.code}', style: const TextStyle(fontSize: 12)),
            if (p?.email?.isNotEmpty == true)
              Text(p!.email!, style: const TextStyle(fontSize: 12, color: Colors.blue)),
            Row(
              children: [
                Icon(
                  p?.isActive == true ? Icons.check_circle : Icons.block,
                  size: 14,
                  color: p?.isActive == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  p?.isActive == true ? 'Hoạt động' : 'Không hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    color: p?.isActive == true ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Chỉnh sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
