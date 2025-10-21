import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/class_entity.dart';
import '../../../bloc/class/class_bloc.dart';
import '../../../bloc/class/class_event.dart';
import '../../../bloc/class/class_state.dart';
import '../Add/AddClassPage.dart';
import '../Edit/EditClassPage.dart';

class AdminClassList extends StatefulWidget {
  const AdminClassList({super.key});

  @override
  State<AdminClassList> createState() => _AdminClassListState();
}

class _AdminClassListState extends State<AdminClassList> {
  // mở thêm lớp
  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddClassPage()),
    );
    if (created == true && mounted) {
      context.read<ClassBloc>().add(const LoadClasses());
    }
  }

  // mở sửa lớp
  Future<void> _openEdit(ClassEntity cls) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditClassPage(
          classEntity: {
            'id': cls.id,
            'code': cls.code ?? '',
            'name': cls.name,
            'faculty_id': cls.facultyId,
            'cohort_id': cls.cohortId,
            // nếu sau này EditClassPage cần thêm field thì bổ sung ở đây
          },
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<ClassBloc>().add(const LoadClasses());
    }
  }

  void _deleteClass(ClassEntity cls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp'),
        content: Text('Bạn muốn xóa lớp "${cls.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ClassBloc>().add(DeleteClass(cls.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ClassBloc, ClassState>(
      builder: (context, state) {
        if (state is ClassLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ClassError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.read<ClassBloc>().add(const LoadClasses()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is ClassesLoaded) {
          final items = state.filteredClasses;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(state.classes.isEmpty ? Icons.class_ : Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    state.classes.isEmpty ? 'Chưa có lớp nào' : 'Không tìm thấy kết quả',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (state.classes.isEmpty)
                    ElevatedButton.icon(
                      onPressed: _openAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm lớp đầu tiên'),
                    ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final cls = items[i];
              return Card(
                child: ListTile(
                  onTap: () => _openEdit(cls), // chạm để edit nhanh
                  title: Text(cls.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cls.code?.isNotEmpty == true) Text('Mã lớp: ${cls.code}'),
                      if (cls.facultyName?.isNotEmpty == true) Text('Khoa: ${cls.facultyName}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          _openEdit(cls);
                          break;
                        case 'delete':
                          _deleteClass(cls);
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
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
            },
          );
        }

        // trạng thái khởi tạo
        return Center(
          child: ElevatedButton.icon(
            onPressed: () => context.read<ClassBloc>().add(const LoadClasses()),
            icon: const Icon(Icons.download),
            label: const Text('Tải danh sách lớp'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Stack để chèn FAB "Thêm"
    return Stack(
      children: [
        _buildBody(),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _openAdd,
            icon: const Icon(Icons.add),
            label: const Text('Thêm lớp'),
          ),
        ),
      ],
    );
  }
}
