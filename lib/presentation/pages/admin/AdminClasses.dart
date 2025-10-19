import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/entity/class_entity.dart';
import '../../../data/models/entity/faculty_entity.dart';
import '../../../data/services/class_service.dart';
import '../../../data/services/faculty_service.dart';
import '../../widgets/loading_widget.dart';

class AdminClasses extends StatefulWidget {
  const AdminClasses({super.key});

  @override
  State<AdminClasses> createState() => _AdminClassesState();
}

class _AdminClassesState extends State<AdminClasses> {
  final TextEditingController _searchController = TextEditingController();
  List<ClassEntity> _classes = [];
  List<ClassEntity> _filteredClasses = [];
  List<FacultyEntity> _faculties = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ClassService.getClasses(),
        FacultyService.getFaculties(),
      ]);

      setState(() {
        _classes = results[0] as List<ClassEntity>;
        _filteredClasses = _classes;
        _faculties = results[1] as List<FacultyEntity>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterClasses(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredClasses = _classes;
      });
      return;
    }

    final filtered = _classes.where((classEntity) {
      return classEntity.name.toLowerCase().contains(query.toLowerCase()) ||
             classEntity.code.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredClasses = filtered;
    });
  }

  void _showClassForm([ClassEntity? classEntity]) {
    showDialog(
      context: context,
      builder: (context) => _ClassFormDialog(
        classEntity: classEntity,
        faculties: _faculties,
        onSaved: _loadData,
      ),
    );
  }

  void _confirmDelete(ClassEntity classEntity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp'),
        content: Text('Bạn muốn xóa lớp ${classEntity.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ClassService.deleteClass(classEntity.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa lớp thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
        title: const Text('Quản lý lớp'),
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
                      hintText: 'Tìm theo tên, mã lớp...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                    onChanged: _filterClasses,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                ElevatedButton.icon(
                  onPressed: () => _showClassForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lớp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải lớp...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredClasses.isEmpty) {
      return const Center(
        child: Text('Chưa có lớp nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: _filteredClasses.length,
      itemBuilder: (context, index) {
        final classEntity = _filteredClasses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Text(
                classEntity.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showClassForm(classEntity);
                    break;
                  case 'delete':
                    _confirmDelete(classEntity);
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
      },
    );
  }
}

class _ClassFormDialog extends StatefulWidget {
  final ClassEntity? classEntity;
  final List<FacultyEntity> faculties;
  final VoidCallback onSaved;

  const _ClassFormDialog({
    this.classEntity,
    required this.faculties,
    required this.onSaved,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  String? _selectedFacultyId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.classEntity?.code ?? '');
    _nameController = TextEditingController(text: widget.classEntity?.name ?? '');
    _selectedFacultyId = widget.classEntity?.facultyId;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.classEntity == null) {
        await ClassService.createClass(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          facultyId: _selectedFacultyId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo lớp thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ClassService.updateClass(
          id: widget.classEntity!.id,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          facultyId: _selectedFacultyId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật lớp thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.classEntity == null ? 'Thêm lớp' : 'Cập nhật lớp',
      ),
      content: Form(
        key: _formKey,
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
                  return 'Nhập mã lớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên lớp *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nhập tên lớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFacultyId,
              decoration: const InputDecoration(
                labelText: 'Khoa',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Chọn khoa'),
                ),
                ...widget.faculties.map((faculty) => DropdownMenuItem<String>(
                      value: faculty.id,
                      child: Text(faculty.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFacultyId = value;
                });
              },
            ),
          ],
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
