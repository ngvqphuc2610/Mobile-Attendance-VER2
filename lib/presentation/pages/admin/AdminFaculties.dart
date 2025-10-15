import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/faculty_model.dart';
import '../../widgets/loading_widget.dart';

class AdminFaculties extends StatefulWidget {
  const AdminFaculties({super.key});

  @override
  State<AdminFaculties> createState() => _AdminFacultiesState();
}

class _AdminFacultiesState extends State<AdminFaculties> {
  final _searchController = TextEditingController();
  List<FacultyModel> _faculties = [];
  List<FacultyModel> _filteredFaculties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getList(ApiConstants.faculties);
      _faculties = response.map((json) => FacultyModel.fromJson(json)).toList();
      _filteredFaculties = _faculties;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterFaculties(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaculties = _faculties;
      } else {
        _filteredFaculties = _faculties.where((faculty) {
          return faculty.name.toLowerCase().contains(query.toLowerCase()) ||
              faculty.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _showAddEditDialog([FacultyModel? faculty]) async {
    final codeController = TextEditingController(text: faculty?.code ?? '');
    final nameController = TextEditingController(text: faculty?.name ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(faculty == null ? 'Thêm khoa' : 'Sửa khoa'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã khoa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã khoa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khoa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên khoa';
                  }
                  return null;
                },
              ),
            ],
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
                  if (faculty == null) {
                    await ApiService.create(ApiConstants.faculties, {
                      'code': codeController.text.trim(),
                      'name': nameController.text.trim(),
                    });
                  } else {
                    await ApiService.update(
                      ApiConstants.faculties,
                      faculty.id.toString(),
                      {
                        'code': codeController.text.trim(),
                        'name': nameController.text.trim(),
                      },
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
            child: Text(faculty == null ? 'Thêm' : 'Cập nhật'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            faculty == null
                ? 'Thêm khoa thành công'
                : 'Cập nhật khoa thành công',
          ),
        ),
      );
      _loadFaculties();
    }
  }

  Future<void> _confirmDelete(FacultyModel faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khoa "${faculty.name}"?'),
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
        await ApiService.delete(ApiConstants.faculties, faculty.id.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa khoa thành công')));
        _loadFaculties();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa khoa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khoa'),
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
                hintText: 'Tìm kiếm khoa...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterFaculties,
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Đang tải danh sách khoa...')
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
                          onPressed: _loadFaculties,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _filteredFaculties.isEmpty
                ? const Center(child: Text('Không có khoa nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: _filteredFaculties.length,
                    itemBuilder: (context, index) {
                      final faculty = _filteredFaculties[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppSizes.paddingSmall,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              faculty.code.isNotEmpty
                                  ? faculty.code[0].toUpperCase()
                                  : 'K',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            faculty.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Mã: ${faculty.code}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showAddEditDialog(faculty);
                                  break;
                                case 'delete':
                                  _confirmDelete(faculty);
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
