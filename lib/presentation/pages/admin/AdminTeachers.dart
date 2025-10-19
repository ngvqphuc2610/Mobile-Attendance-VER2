import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/teacher_entity.dart';
import '../../bloc/teacher/teacher_bloc.dart';
import '../../bloc/teacher/teacher_event.dart';
import '../../bloc/teacher/teacher_state.dart';

// ✅ Bạn đã import 2 trang này rồi
import 'add/AddTeacherPage.dart';
import 'edit/EditTeacherPage.dart';

class AdminTeachers extends StatefulWidget {
  const AdminTeachers({super.key});

  @override
  State<AdminTeachers> createState() => _AdminTeachersState();
}

class _AdminTeachersState extends State<AdminTeachers> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeacherBloc>().add(const LoadTeachers());
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
      context.read<TeacherBloc>().add(FilterTeachers(query.trim()));
    });
  }

  // ===== MỞ TRANG THÊM / SỬA =====
  Future<void> _openAddTeacher() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTeacherPage()),
    );
    if (created == true && mounted) {
      context.read<TeacherBloc>().add(const LoadTeachers());
    }
  }

  Future<void> _openEditTeacher(TeacherEntity teacher) async {
    final payload = {
      'profile_id': teacher.profileId,
      'code': teacher.profile?.code,
      'full_name': teacher.profile?.fullName,
      'email': teacher.profile?.email,
      'phone': teacher.profile?.phone,
      'faculty_id': teacher.facultyId,
      'title': teacher.title,
      'office': teacher.office,
    };

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTeacherPage(teacher: payload),
      ),
    );
    if (updated == true && mounted) {
      context.read<TeacherBloc>().add(const LoadTeachers());
    }
  }

  void _confirmDelete(TeacherEntity teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giảng viên'),
        content: Text(
          'Bạn muốn xóa giảng viên ${teacher.profile?.fullName ?? teacher.profileId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TeacherBloc>().add(DeleteTeacher(teacher.profileId));
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
      appBar: AppBar(
        title: const Text('Quản lý giảng viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // ✅ FAB thêm GV
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTeacher,
        icon: const Icon(Icons.add),
        label: const Text('Thêm giảng viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is TeacherOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            // Reload danh sách sau create/update/delete
            context.read<TeacherBloc>().add(const LoadTeachers());
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ép toàn bộ nội dung có width hữu hạn
              Widget wrap(Widget child) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: child,
                    ),
                  );

              // Header (search + add) dùng Sliver
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
                                hintText: 'Tìm theo tên, mã, email...',
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
                          // ✅ Nút "Thêm GV" ở header cũng đi tới trang AddTeacherPage
                          ElevatedButton.icon(
                            onPressed: _openAddTeacher,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm GV'),
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

              return BlocBuilder<TeacherBloc, TeacherState>(
                builder: (context, state) {
                  if (state is TeacherLoading) {
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

                  if (state is TeacherError) {
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

                  if (state is TeachersLoaded) {
                    final items = state.filteredTeachers;

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
                                      state.teachers.isEmpty ? Icons.people_outline : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.teachers.isEmpty
                                          ? 'Chưa có giảng viên nào'
                                          : 'Không tìm thấy kết quả',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    if (state.teachers.isEmpty)
                                      ElevatedButton.icon(
                                        onPressed: _openAddTeacher,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm giảng viên đầu tiên'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return wrap(
                      CustomScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          header(),
                          SliverList.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final t = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                                child: KeyedSubtree(
                                  key: ValueKey(t.profileId),
                                  child: _TeacherCard(
                                    teacher: t,
                                    onEdit: () => _openEditTeacher(t), // ✅ mở trang Edit
                                    onDelete: () => _confirmDelete(t),
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
                              onPressed: () => context.read<TeacherBloc>().add(const LoadTeachers()),
                              icon: const Icon(Icons.download),
                              label: const Text('Tải danh sách giảng viên'),
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

class _TeacherCard extends StatelessWidget {
  final TeacherEntity teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = teacher.profile;
    final name = (p?.fullName ?? '').trim();
    final initials = name.isNotEmpty ? name.characters.first.toUpperCase() : 'T';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Text(
            initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name.isNotEmpty ? name : 'Chưa có tên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p?.code?.isNotEmpty == true) Text('Mã GV: ${p!.code}'),
            if (teacher.title?.isNotEmpty == true) Text('Chức danh: ${teacher.title}'),
            if (teacher.office?.isNotEmpty == true) Text('Phòng: ${teacher.office}'),
            if (p?.email?.isNotEmpty == true) Text('Email: ${p!.email}'),
            Text('Trạng thái: ${p?.isActive == true ? "Hoạt động" : "Không hoạt động"}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
                leading: Icon(Icons.edit),
                title: Text('Sửa'),
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
