import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
// removed unused imports
import '../../widgets/loading_widget.dart';

class AdminStudent extends StatefulWidget {
  const AdminStudent({super.key});

  @override
  State<AdminStudent> createState() => _AdminStudentState();
}

class _AdminStudentState extends State<AdminStudent> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _classes = [];
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
      // Load students and classes
      final studentsResponse = await ApiService.getList(ApiConstants.students);
      final classesResponse = await ApiService.getList(ApiConstants.classes);

      _students = List<Map<String, dynamic>>.from(studentsResponse);
      _classes = List<Map<String, dynamic>>.from(classesResponse);
      _filteredStudents = _students;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          return student['full_name']?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ==
                  true ||
              student['code']?.toLowerCase().contains(query.toLowerCase()) ==
                  true ||
              student['mssv']?.toLowerCase().contains(query.toLowerCase()) ==
                  true;
        }).toList();
      }
    });
  }

  Future<void> _showAddEditDialog([Map<String, dynamic>? student]) async {
    final codeController = TextEditingController(text: student?['code'] ?? '');
    final nameController = TextEditingController(
      text: student?['full_name'] ?? '',
    );
    final emailController = TextEditingController(
      text: student?['email'] ?? '',
    );
    final phoneController = TextEditingController(
      text: student?['phone'] ?? '',
    );
    final mssvController = TextEditingController(text: student?['mssv'] ?? '');
    final passwordController = TextEditingController();

    String? selectedClassId = student?['class_id'];
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(student == null ? 'Thêm sinh viên' : 'Sửa sinh viên'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã sinh viên',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã sinh viên';
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
                  controller: mssvController,
                  decoration: const InputDecoration(
                    labelText: 'MSSV',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Lớp học',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Chọn lớp học'),
                    ),
                    ..._classes.map(
                      (cls) => DropdownMenuItem<String?>(
                        value: cls['id'],
                        child: Text('${cls['code']} - ${cls['name']}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    selectedClassId = value;
                  },
                ),
                if (student == null) ...[
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
                    'class_id': selectedClassId,
                    'mssv': mssvController.text.trim().isEmpty
                        ? null
                        : mssvController.text.trim(),
                  };

                  if (student == null) {
                    data['password'] = passwordController.text.trim().isEmpty
                        ? '123456'
                        : passwordController.text.trim();
                    await ApiService.create(ApiConstants.students, data);
                  } else {
                    await ApiService.update(
                      ApiConstants.students,
                      student['profile_id'].toString(),
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
            child: Text(student == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            student == null
                ? 'Thêm sinh viên thành công'
                : 'Cập nhật sinh viên thành công',
          ),
        ),
      );
      _loadData();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa sinh viên "${student['full_name']}"?',
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
          ApiConstants.students,
          student['profile_id'].toString(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa sinh viên thành công')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa sinh viên: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
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
                hintText: 'Tìm kiếm sinh viên...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterStudents,
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const LoadingWidget(
                    message: 'Đang tải danh sách sinh viên...',
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
                : _filteredStudents.isEmpty
                ? const Center(child: Text('Không có sinh viên nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppSizes.paddingSmall,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              student['full_name']?.isNotEmpty == true
                                  ? student['full_name'][0].toUpperCase()
                                  : 'SV',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student['full_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mã: ${student['code'] ?? ''}'),
                              if (student['mssv'] != null)
                                Text('MSSV: ${student['mssv']}'),
                              if (student['class_name'] != null)
                                Text('Lớp: ${student['class_name']}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showAddEditDialog(student);
                                  break;
                                case 'delete':
                                  _confirmDelete(student);
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
