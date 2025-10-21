import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/class_section_entity.dart';
import '../../../bloc/class_section/class_section_bloc.dart';
import '../../../bloc/class_section/class_section_event.dart';
import '../../../bloc/class_section/class_section_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Add/AddClassSectionPage.dart';
import '../Edit/EditClassSectionPage.dart';

class AdminClassSectionList extends StatefulWidget {
  const AdminClassSectionList({super.key});

  @override
  State<AdminClassSectionList> createState() => _AdminClassSectionListState();
}

class _AdminClassSectionListState extends State<AdminClassSectionList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load sau frame đầu tiên để chắc chắn context đã có BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClassSectionBloc>().add(const LoadClassSections());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<ClassSectionBloc>().add(FilterClassSections(q.trim()));
    });
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddClassSectionPage()),
    );
    if (created == true && mounted) {
      context.read<ClassSectionBloc>().add(const LoadClassSections());
    }
  }

  Future<void> _openEdit(ClassSectionEntity section) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditClassSectionPage(
          // EditClassSectionPage nhận Map<String, dynamic> tên tham số: classSection
          classSection: section.toJson(),
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<ClassSectionBloc>().add(const LoadClassSections());
    }
  }

  void _delete(ClassSectionEntity section) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp học phần'),
        content: Text('Bạn muốn xóa lớp học phần "${section.sectionCode}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ClassSectionBloc>().add(DeleteClassSection(section.id));
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

  Widget _buildBody() {
    return BlocBuilder<ClassSectionBloc, ClassSectionState>(
      builder: (context, state) {
        if (state is ClassSectionLoading) {
          return const LoadingWidget(message: 'Đang tải danh sách lớp học phần...');
        }

        if (state is ClassSectionError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lỗi: ${state.message}'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.read<ClassSectionBloc>().add(const LoadClassSections()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is ClassSectionsLoaded) {
          final items = state.filteredSections;
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có lớp học phần nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final section = items[index];
              return Card(
                child: ListTile(
                  onTap: () => _openEdit(section), // chạm để edit nhanh
                  title: Text(
                    section.sectionCode,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Môn học: ${section.subject?.name ?? "-"}'),
                      Text('Học kỳ: ${section.semester}/${section.year}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          _openEdit(section);
                          break;
                        case 'delete':
                          _delete(section);
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

        return const Center(child: Text('Chưa có lớp học phần nào'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm theo mã lớp, môn học...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),

        // FAB Thêm
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
