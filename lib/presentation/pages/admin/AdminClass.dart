import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/class_entity.dart';
import '../../../data/models/entity/faculty_entity.dart';
import '../../../data/models/entity/cohort.dart';
import '../../bloc/class/class_bloc.dart';
import '../../bloc/class/class_event.dart';
import '../../bloc/class/class_state.dart';
import '../../widgets/loading_widget.dart';

class AdminClass extends StatefulWidget {
  const AdminClass({super.key});

  @override
  State<AdminClass> createState() => _AdminClassState();
}

class _AdminClassState extends State<AdminClass> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClassBloc>().add(const LoadClasses());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showClassDialog([ClassEntity? classEntity]) {
    showDialog(
      context: context,
      builder: (context) => _ClassFormDialog(
        classEntity: classEntity,
        onSaved: () {
          context.read<ClassBloc>().add(const LoadClasses());
        },
      ),
    );
  }

  void _showDeleteDialog(ClassEntity classEntity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa lớp "${classEntity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ClassBloc>().add(DeleteClass(classEntity.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lớp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<ClassBloc, ClassState>(
        listener: (context, state) {
          if (state is ClassError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ClassOperationSuccess) {
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
              child: BlocBuilder<ClassBloc, ClassState>(
                builder: (context, state) {
                  if (state is ClassLoading) {
                    return const LoadingWidget(message: 'Đang tải danh sách lớp...');
                  }

                  if (state is ClassError) {
                    return _ErrorRetry(
                      message: state.message,
                      onRetry: () {
                        context.read<ClassBloc>().add(const LoadClasses());
                      },
                    );
                  }

                  if (state is ClassesLoaded) {
                    if (state.filteredClasses.isEmpty) {
                      return const Center(
                        child: Text('Chưa có lớp nào'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: state.filteredClasses.length,
                      itemBuilder: (context, index) {
                        final classEntity = state.filteredClasses[index];
                        return _ClassCard(
                          classEntity: classEntity,
                          onEdit: () => _showClassDialog(classEntity),
                          onDelete: () => _showDeleteDialog(classEntity),
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
        onPressed: () => _showClassDialog(),
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
          hintText: 'Tìm kiếm theo tên, mã lớp...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        onChanged: (query) {
          context.read<ClassBloc>().add(FilterClasses(query));
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassEntity classEntity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.classEntity,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.class_, color: Colors.white),
        ),
        title: Text(
          classEntity.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã lớp: ${classEntity.code}'),
            if (classEntity.faculty != null)
              Text('Khoa: ${classEntity.faculty!.name}'),
            if (classEntity.cohort != null)
              Text('Khóa: ${classEntity.cohort!.year}'),
            Text('Tạo: ${_formatDate(classEntity.createdAt)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
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
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ClassFormDialog extends StatefulWidget {
  final ClassEntity? classEntity;
  final VoidCallback onSaved;

  const _ClassFormDialog({
    this.classEntity,
    required this.onSaved,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedFacultyId;
  String? _selectedCohortId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classEntity != null) {
      _codeController.text = widget.classEntity!.code;
      _nameController.text = widget.classEntity!.name;
      _selectedFacultyId = widget.classEntity!.facultyId;
      _selectedCohortId = widget.classEntity!.cohortId;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (widget.classEntity != null) {
      context.read<ClassBloc>().add(UpdateClass(
        id: widget.classEntity!.id,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        facultyId: _selectedFacultyId,
        cohortId: _selectedCohortId,
      ));
    } else {
      context.read<ClassBloc>().add(CreateClass(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        facultyId: _selectedFacultyId,
        cohortId: _selectedCohortId,
      ));
    }

    Navigator.of(context).pop();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classEntity != null ? 'Sửa lớp' : 'Thêm lớp mới'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã lớp *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã lớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên lớp *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên lớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Khoa',
                  border: OutlineInputBorder(),
                ),
                value: _selectedFacultyId,
                items: const [], // TODO: Load from FacultyBloc
                onChanged: (value) {
                  setState(() => _selectedFacultyId = value);
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Khóa học',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCohortId,
                items: const [], // TODO: Load from CohortBloc
                onChanged: (value) {
                  setState(() => _selectedCohortId = value);
                },
              ),
            ],
          ),
        ),
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

  const _ErrorRetry({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
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