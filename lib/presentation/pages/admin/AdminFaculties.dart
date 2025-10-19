import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/faculty_entity.dart';
import '../../bloc/faculty/faculty_bloc.dart';
import '../../bloc/faculty/faculty_event.dart';
import '../../bloc/faculty/faculty_state.dart';
import '../../widgets/loading_widget.dart';
import 'add/AddFacultyPage.dart';
import 'edit/EditFacultyPage.dart';

class AdminFaculties extends StatefulWidget {
  const AdminFaculties({super.key});

  @override
  State<AdminFaculties> createState() => _AdminFacultiesState();
}

class _AdminFacultiesState extends State<AdminFaculties> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load sau frame đầu tiên để chắc chắn context đã có Bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FacultyBloc>().add(const LoadFaculties());
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
      context.read<FacultyBloc>().add(FilterFaculties(q.trim()));
    });
  }

  Future<void> _showAddFacultyPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFacultyPage()),
    );
    if (!mounted) return;
    context.read<FacultyBloc>().add(const LoadFaculties()); // reload sau khi quay lại
  }

  Future<void> _showEditFacultyPage(FacultyEntity faculty) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditFacultyPage(faculty: faculty)),
    );
    if (!mounted) return;
    context.read<FacultyBloc>().add(const LoadFaculties());
  }

  void _showDeleteDialog(FacultyEntity faculty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khoa "${faculty.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FacultyBloc>().add(DeleteFaculty(faculty.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        title: const Text('Quản lý khoa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFacultyPage,
        icon: const Icon(Icons.add),
        label: const Text('Thêm khoa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<FacultyBloc, FacultyState>(
        listener: (context, state) {
          if (state is FacultyOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            context.read<FacultyBloc>().add(const LoadFaculties());
          } else if (state is FacultyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
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
                                hintText: 'Tìm theo tên khoa...',
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
                            onPressed: _showAddFacultyPage,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm khoa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingMedium, vertical: AppSizes.paddingSmall),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

              return BlocBuilder<FacultyBloc, FacultyState>(
                builder: (context, state) {
                  if (state is FacultyLoading) {
                    return wrap(
                      CustomScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: const [
                          SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverFillRemaining(hasScrollBody: false, child: Center(child: LoadingWidget())),
                        ],
                      ),
                    );
                  }

                  if (state is FacultyError) {
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

                  if (state is FacultiesLoaded) {
                    final items = state.filteredFaculties;

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
                                      state.faculties.isEmpty ? Icons.apartment_outlined : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.faculties.isEmpty
                                          ? 'Chưa có khoa nào'
                                          : 'Không tìm thấy kết quả',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    if (state.faculties.isEmpty)
                                      ElevatedButton.icon(
                                        onPressed: _showAddFacultyPage,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm khoa đầu tiên'),
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
                              final f = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                                child: Card(
                                  child: ListTile(
                                    title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('Mã khoa: ${f.code}'),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) {
                                        switch (v) {
                                          case 'edit':
                                            _showEditFacultyPage(f);
                                            break;
                                          case 'delete':
                                            _showDeleteDialog(f);
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
                              onPressed: () => context.read<FacultyBloc>().add(const LoadFaculties()),
                              icon: const Icon(Icons.download),
                              label: const Text('Tải danh sách khoa'),
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
