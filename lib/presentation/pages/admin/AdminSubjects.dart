
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/subject_entity.dart';
import '../../bloc/subject/subject_bloc.dart';
import '../../bloc/subject/subject_event.dart';
import '../../bloc/subject/subject_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class AdminSubjects extends StatefulWidget {
  const AdminSubjects({super.key});

  @override
  State<AdminSubjects> createState() => _AdminSubjectsState();
}

class _AdminSubjectsState extends State<AdminSubjects> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SubjectBloc>().add(const LoadSubjects());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSubjectForm([SubjectEntity? subject]) {
    showDialog(
      context: context,
      builder: (context) => _SubjectFormDialog(subject: subject),
    );
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
              context.read<SubjectBloc>().add(DeleteSubject(subject.id));
              Navigator.of(ctx).pop();
            },
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
      body: Column(
        children: [
          Padding(
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
                    ),
                    onChanged: (query) {
                      context.read<SubjectBloc>().add(FilterSubjects(query));
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                ElevatedButton.icon(
                  onPressed: () => _showSubjectForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm môn học'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingSmall,
                      horizontal: AppSizes.paddingMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SubjectBloc, SubjectState>(
              builder: (context, state) {
                if (state is SubjectLoading) {
                  return const LoadingWidget(message: 'Đang tải môn học...');
                }

                if (state is SubjectError) {
                  return _ErrorRetry(
                    message: state.message,
                    onRetry: () {
                      context.read<SubjectBloc>().add(const LoadSubjects());
                    },
                  );
                }

                if (state is SubjectsLoaded) {
                  if (state.filteredSubjects.isEmpty) {
                    return const Center(
                      child: Text('Chưa có môn học nào'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: state.filteredSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = state.filteredSubjects[index];
                      return Card(
                        child: ListTile(
                          title: Text(subject.name),
                          subtitle: Text('Mã: ${subject.code}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showSubjectForm(subject),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDelete(subject),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectFormDialog extends StatefulWidget {
  final SubjectEntity? subject;

  const _SubjectFormDialog({this.subject});

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _creditsController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.subject?.code ?? '');
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _creditsController = TextEditingController(
      text: widget.subject?.credits?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final credits = int.tryParse(_creditsController.text.trim());

    if (credits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tín chỉ phải là số nguyên')),
      );
      return;
    }

    final bloc = context.read<SubjectBloc>();
    if (widget.subject == null) {
      bloc.add(CreateSubject(code, name, credits));
    } else {
      bloc.add(UpdateSubject(
        widget.subject!.id,
        code,
        name,
        credits,
      ));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subject == null ? 'Thêm môn học' : 'Cập nhật môn học'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã môn học *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập mã môn học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên môn học *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập tên môn học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(
                  labelText: 'Số tín chỉ *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập số tín chỉ';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Lưu'),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
