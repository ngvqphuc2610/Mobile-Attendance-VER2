import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/student_entity.dart';
import '../../../data/models/dto/student_dto.dart';
import '../../bloc/student/student_bloc.dart';
import '../../bloc/student/student_event.dart';
import '../../bloc/student/student_state.dart';
import '../../widgets/loading_widget.dart';

class AdminStudents extends StatefulWidget {
  const AdminStudents({super.key});

  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StudentBloc>().add(const LoadStudents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStudentForm([StudentEntity? student]) {
    showDialog(
      context: context,
      builder: (context) => _StudentFormDialog(student: student),
    );
  }

  void _confirmDelete(StudentEntity student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sinh viên'),
        content: Text(
          'Bạn muốn xóa sinh viên ${student.profile?.fullName ?? student.profileId}?',
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
        title: const Text('Quản lý sinh viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is StudentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is StudentOperationSuccess) {
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
            // Search and Add button
            Padding(
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
                      ),
                      onChanged: (query) {
                        context.read<StudentBloc>().add(FilterStudents(query));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  ElevatedButton.icon(
                    onPressed: () => _showStudentForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm SV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentLoading) {
                    return const LoadingWidget(message: 'Đang tải sinh viên...');
                  }
                  
                  if (state is StudentError) {
                    return _ErrorRetry(
                      message: state.message,
                      onRetry: () {
                        context.read<StudentBloc>().add(const LoadStudents());
                      },
                    );
                  }
                  
                  if (state is StudentsLoaded) {
                    if (state.filteredStudents.isEmpty) {
                      return const Center(
                        child: Text('Chưa có sinh viên nào'),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: state.filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = state.filteredStudents[index];
                        return _StudentCard(
                          student: student,
                          onEdit: () => _showStudentForm(student),
                          onDelete: () => _confirmDelete(student),
                        );
                      },
                    );
                  }
                  
                  return const Center(
                    child: Text('Không có dữ liệu'),
                  );
                },
              ),
            ),
          ],
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
    final profile = student.profile;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Text(
            profile?.fullName.substring(0, 1).toUpperCase() ?? 'S',
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
            if (student.mssv != null) Text('MSSV: ${student.mssv}'),
            if (profile?.code != null) Text('Mã SV: ${profile!.code}'),
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
                title: Text(
                  'Xóa',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentFormDialog extends StatefulWidget {
  final StudentEntity? student;

  const _StudentFormDialog({this.student});

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _codeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _mssvController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final profile = widget.student?.profile;
    
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _codeController = TextEditingController(text: profile?.code ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _mssvController = TextEditingController(text: widget.student?.mssv ?? '');
    _isActive = profile?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mssvController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final studentDto = StudentDto(
      fullName: _fullNameController.text.trim(),
      code: _codeController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      mssv: _mssvController.text.trim().isEmpty ? null : _mssvController.text.trim(),
      isActive: _isActive,
    );

    final bloc = context.read<StudentBloc>();
    
    if (widget.student == null) {
      bloc.add(CreateStudent(studentDto));
    } else {
      bloc.add(UpdateStudent(
        id: widget.student!.profileId,
        studentDto: studentDto,
      ));
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.student == null ? 'Thêm sinh viên' : 'Cập nhật sinh viên',
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
                  labelText: 'Mã sinh viên *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập mã sinh viên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mssvController,
                decoration: const InputDecoration(
                  labelText: 'MSSV',
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