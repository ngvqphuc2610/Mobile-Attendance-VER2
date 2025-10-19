import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/teacher_entity.dart';
import '../../../data/models/dto/teacher_dto.dart';
import '../../bloc/teacher/teacher_bloc.dart';
import '../../bloc/teacher/teacher_event.dart';
import '../../bloc/teacher/teacher_state.dart';
import '../../widgets/loading_widget.dart';

class AdminTeachers extends StatefulWidget {
  const AdminTeachers({super.key});

  @override
  State<AdminTeachers> createState() => _AdminTeachersState();
}

class _AdminTeachersState extends State<AdminTeachers> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(const LoadTeachers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTeacherForm([TeacherEntity? teacher]) {
    showDialog(
      context: context,
      builder: (context) => _TeacherFormDialog(teacher: teacher),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is TeacherError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TeacherOperationSuccess) {
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
            Padding(
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
                      ),
                      onChanged: (query) {
                        context.read<TeacherBloc>().add(FilterTeachers(query));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  ElevatedButton.icon(
                    onPressed: () => _showTeacherForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm GV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<TeacherBloc, TeacherState>(
                builder: (context, state) {
                  if (state is TeacherLoading) {
                    return const LoadingWidget(message: 'Đang tải giảng viên...');
                  }

                  if (state is TeacherError) {
                    return _ErrorRetry(
                      message: state.message,
                      onRetry: () {
                        context.read<TeacherBloc>().add(const LoadTeachers());
                      },
                    );
                  }

                  if (state is TeachersLoaded) {
                    if (state.filteredTeachers.isEmpty) {
                      return const Center(
                        child: Text('Chưa có giảng viên nào'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: state.filteredTeachers.length,
                      itemBuilder: (context, index) {
                        final teacher = state.filteredTeachers[index];
                        return _TeacherCard(
                          teacher: teacher,
                          onEdit: () => _showTeacherForm(teacher),
                          onDelete: () => _confirmDelete(teacher),
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
    final profile = teacher.profile;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Text(
            profile?.fullName.substring(0, 1).toUpperCase() ?? 'T',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          profile?.fullName ?? 'Chưa có tên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile?.code != null) Text('Mã GV: ${profile!.code}'),
            if (teacher.title != null) Text('Chức danh: ${teacher.title}'),
            if (teacher.office != null) Text('Phòng: ${teacher.office}'),
            if (profile?.email != null) Text('Email: ${profile!.email}'),
            Text('Trạng thái: ${profile?.isActive == true ? "Hoạt động" : "Không hoạt động"}'),
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
  }
}

class _TeacherFormDialog extends StatefulWidget {
  final TeacherEntity? teacher;

  const _TeacherFormDialog({this.teacher});

  @override
  State<_TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<_TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _codeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _titleController;
  late final TextEditingController _officeController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final profile = widget.teacher?.profile;

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _codeController = TextEditingController(text: profile?.code ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _titleController = TextEditingController(text: widget.teacher?.title ?? '');
    _officeController = TextEditingController(text: widget.teacher?.office ?? '');
    _isActive = profile?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final teacherDto = TeacherDto(
      fullName: _fullNameController.text.trim(),
      code: _codeController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      office: _officeController.text.trim().isEmpty ? null : _officeController.text.trim(),
      isActive: _isActive,
    );

    final bloc = context.read<TeacherBloc>();

    if (widget.teacher == null) {
      bloc.add(CreateTeacher(teacherDto));
    } else {
      bloc.add(UpdateTeacher(
        id: widget.teacher!.profileId,
        teacherDto: teacherDto,
      ));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.teacher == null ? 'Thêm giảng viên' : 'Cập nhật giảng viên',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã giảng viên *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập mã giảng viên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Chức danh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _officeController,
                decoration: const InputDecoration(
                  labelText: 'Phòng làm việc',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Hoạt động'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
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