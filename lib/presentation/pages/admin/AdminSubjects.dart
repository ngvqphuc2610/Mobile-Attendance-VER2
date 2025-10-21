import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile_attendance/presentation/pages/admin/Add/AddSubjectPage.dart';
import 'package:mobile_attendance/presentation/pages/admin/Edit/EditSubjectPage.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/subject_entity.dart';
import '../../bloc/subject/subject_bloc.dart';
import '../../bloc/subject/subject_event.dart';
import '../../bloc/subject/subject_state.dart';

class AdminSubjects extends StatefulWidget {
  const AdminSubjects({super.key});

  @override
  State<AdminSubjects> createState() => _AdminSubjectsState();
}

class _AdminSubjectsState extends State<AdminSubjects> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load sau frame đầu tiên để chắc chắn context đã có SubjectBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubjectBloc>().add(const LoadSubjects());
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
      context.read<SubjectBloc>().add(FilterSubjects(q.trim()));
    });
  }

  Future<void> _openAddSubject() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSubjectPage()),
    );
    if (!mounted) return;
    if (created == true) {
      context.read<SubjectBloc>().add(const LoadSubjects());
    }
  }

Future<void> _openEditSubject(SubjectEntity subject) async {
  final updated = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<SubjectBloc>(), // dùng cùng instance
        child: EditSubjectPage(subject: subject),
      ),
    ),
  );
  if (!mounted) return;
  if (updated == true) {
    context.read<SubjectBloc>().add(const LoadSubjects());
  }
}
  void _confirmDelete(SubjectEntity subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa môn học'),
        content: Text('Bạn muốn xóa môn học ${subject.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SubjectBloc>().add(DeleteSubject(subject.id));
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
        title: const Text('Quản lý môn học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSubject,
        icon: const Icon(Icons.add),
        label: const Text('Thêm môn học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<SubjectBloc, SubjectState>(
        listener: (context, state) {
          if (state is SubjectError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is SubjectOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            context.read<SubjectBloc>().add(const LoadSubjects());
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
                                hintText: 'Tìm theo tên, mã môn học...',
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
                            onPressed: _openAddSubject,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm môn học'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingSmall,
                                horizontal: AppSizes.paddingMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

              return BlocBuilder<SubjectBloc, SubjectState>(
                builder: (context, state) {
                  if (state is SubjectLoading) {
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

                  if (state is SubjectError) {
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

                  if (state is SubjectsLoaded) {
                    final items = state.filteredSubjects;

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
                                      state.subjects.isEmpty ? Icons.library_books_outlined : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.subjects.isEmpty
                                          ? 'Chưa có môn học nào'
                                          : 'Không tìm thấy kết quả',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    if (state.subjects.isEmpty)
                                      ElevatedButton.icon(
                                        onPressed: _openAddSubject,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm môn học đầu tiên'),
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
                                child: Card(
                                  child: ListTile(
                                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (s.code.isNotEmpty) Text('Mã: ${s.code}'),
                                        if (s.credits != null) Text('Số tín chỉ: ${s.credits}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _openEditSubject(s),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDelete(s),
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
                              onPressed: () => context.read<SubjectBloc>().add(const LoadSubjects()),
                              icon: const Icon(Icons.download),
                              label: const Text('Tải danh sách môn học'),
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
