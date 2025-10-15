import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../widgets/loading_widget.dart';

class AdminTeacher extends StatefulWidget {
  const AdminTeacher({super.key});

  @override
  State<AdminTeacher> createState() => _AdminTeacherState();
}

class _AdminTeacherState extends State<AdminTeacher> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  List<Map<String, dynamic>> _faculties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load teachers and faculties
      final teachersResponse = await ApiService.getList(ApiConstants.teachers);
      final facultiesResponse = await ApiService.getList(
        ApiConstants.faculties,
      );

      _teachers = List<Map<String, dynamic>>.from(teachersResponse);
      _faculties = List<Map<String, dynamic>>.from(facultiesResponse);
      _filteredTeachers = _teachers;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterTeachers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeachers = _teachers;
      } else {
        _filteredTeachers = _teachers.where((teacher) {
          return teacher['full_name']?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ==
                  true ||
              teacher['code']?.toLowerCase().contains(query.toLowerCase()) ==
                  true ||
              teacher['email']?.toLowerCase().contains(query.toLowerCase()) ==
                  true;
        }).toList();
      }
    });
  }

  Future<void> _toggleTeacherStatus(Map<String, dynamic> teacher) async {
    try {
      final newStatus = !(teacher['is_active'] ?? true);
      await ApiService.update(
        ApiConstants.teachers,
        teacher['profile_id'].toString(),
        {'is_active': newStatus},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Đã kích hoạt giáo viên' : 'Đã vô hiệu hóa giáo viên',
          ),
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _showAddEditDialog([Map<String, dynamic>? teacher]) async {
    final codeController = TextEditingController(text: teacher?['code'] ?? '');
    final nameController = TextEditingController(
      text: teacher?['full_name'] ?? '',
    );
    final emailController = TextEditingController(
      text: teacher?['email'] ?? '',
    );
    final phoneController = TextEditingController(
      text: teacher?['phone'] ?? '',
    );
    final titleController = TextEditingController(
      text: teacher?['title'] ?? '',
    );
    final officeController = TextEditingController(
      text: teacher?['office'] ?? '',
    );
    final passwordController = TextEditingController();

    String? selectedFacultyId = teacher?['faculty_id'];
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(teacher == null ? 'Thêm giáo viên' : 'Sửa giáo viên'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã giáo viên',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã giáo viên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Chức danh',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: officeController,
                  decoration: const InputDecoration(
                    labelText: 'Phòng làm việc',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFacultyId,
                  decoration: const InputDecoration(
                    labelText: 'Khoa',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Chọn khoa'),
                    ),
                    ..._faculties.map(
                      (faculty) => DropdownMenuItem<String>(
                        value: faculty['id'],
                        child: Text('${faculty['code']} - ${faculty['name']}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    selectedFacultyId = value;
                  },
                ),
                if (teacher == null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu (để trống = 123456)',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final data = {
                    'code': codeController.text.trim(),
                    'full_name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'title': titleController.text.trim().isEmpty
                        ? null
                        : titleController.text.trim(),
                    'office': officeController.text.trim().isEmpty
                        ? null
                        : officeController.text.trim(),
                    'faculty_id': selectedFacultyId,
                  };

                  if (teacher == null) {
                    data['password'] = passwordController.text.trim().isEmpty
                        ? '123456'
                        : passwordController.text.trim();
                    await ApiService.create(ApiConstants.teachers, data);
                  } else {
                    // ApiService.update expects (endpoint, id, data)
                    await ApiService.update(
                      ApiConstants.teachers,
                      teacher['profile_id'].toString(),
                      data,
                    );
                  }
                  Navigator.pop(ctx, true);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: Text(teacher == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            teacher == null
                ? 'Thêm giáo viên thành công'
                : 'Cập nhật giáo viên thành công',
          ),
        ),
      );
      _loadData();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa giáo viên "${teacher['full_name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete(
          ApiConstants.teachers,
          teacher['profile_id'].toString(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa giáo viên thành công')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa giáo viên: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý giáo viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm giáo viên...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterTeachers,
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const LoadingWidget(
                    message: 'Đang tải danh sách giáo viên...',
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _filteredTeachers.isEmpty
                ? const Center(child: Text('Không có giáo viên nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: _filteredTeachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _filteredTeachers[index];
                      final isActive = teacher['is_active'] ?? true;

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppSizes.paddingSmall,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? AppColors.primary
                                : Colors.grey,
                            child: Text(
                              teacher['full_name']?.isNotEmpty == true
                                  ? teacher['full_name'][0].toUpperCase()
                                  : 'GV',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            teacher['full_name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mã: ${teacher['code'] ?? ''}'),
                              Text('Email: ${teacher['email'] ?? ''}'),
                              if (teacher['faculty_name'] != null)
                                Text('Khoa: ${teacher['faculty_name']}'),
                              if (teacher['title'] != null)
                                Text('Chức danh: ${teacher['title']}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: isActive,
                                onChanged: (value) =>
                                    _toggleTeacherStatus(teacher),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _showAddEditDialog(teacher);
                                      break;
                                    case 'delete':
                                      _confirmDelete(teacher);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Sửa'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Xóa',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
