import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import 'add/AddTeacherPage.dart';
import 'edit/EditTeacherPage.dart';

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
  String? _selectedFacultyFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    try {
      final response = await Supabase.instance.client
          .from('faculties')
          .select('id, name')
          .order('name');
      
      setState(() {
        _faculties = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading faculties: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teachersResponse = await Supabase.instance.client
          .from('teachers')
          .select('''
            *,
            profiles!inner (
              id, code, full_name, is_active, email, phone, created_at
            ),
            faculties (
              id, name, code
            )
          ''')
          .order('profiles(full_name)');

      _teachers = List<Map<String, dynamic>>.from(teachersResponse);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _teachers;

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((teacher) {
        final profile = teacher['profiles'] ?? {};
        final name = profile['full_name']?.toString().toLowerCase() ?? '';
        final code = profile['code']?.toString().toLowerCase() ?? '';
        final email = profile['email']?.toString().toLowerCase() ?? '';
        final title = teacher['title']?.toString().toLowerCase() ?? '';
        final facultyName = teacher['faculties']?['name']?.toString().toLowerCase() ?? '';
        
        return name.contains(query) ||
               code.contains(query) ||
               email.contains(query) ||
               title.contains(query) ||
               facultyName.contains(query);
      }).toList();
    }

    // Filter by faculty
    if (_selectedFacultyFilter != null) {
      filtered = filtered.where((teacher) {
        return teacher['faculty_id'] == _selectedFacultyFilter;
      }).toList();
    }

    setState(() {
      _filteredTeachers = filtered;
    });
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTeacherPage()),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEdit(Map<String, dynamic> teacher) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTeacherPage(teacher: teacher),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Giáo viên'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _navigateToAdd),
        ],
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
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Faculty filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
            child: DropdownButtonFormField<String>(
              value: _selectedFacultyFilter,
              decoration: const InputDecoration(
                labelText: 'Lọc theo khoa',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả khoa')),
                ..._faculties.map((faculty) => DropdownMenuItem(
                  value: faculty['id'],
                  child: Text(faculty['name']),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedFacultyFilter = value);
                _applyFilters();
              },
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error'))
                    : _filteredTeachers.isEmpty
                        ? const Center(child: Text('Không có giáo viên nào'))
                        : ListView.builder(
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _filteredTeachers[index];
                              final profile = teacher['profiles'] ?? {};
                              final facultyName = teacher['faculties']?['name'] ?? 'Chưa có khoa';
                              final title = teacher['title'] ?? '';
                              final isActive = profile['is_active'] ?? true;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingMedium,
                                  vertical: AppSizes.paddingSmall,
                                ),
                                child: ListTile(
                                  title: Text(profile['full_name'] ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Mã: ${profile['code'] ?? ''}'),
                                      if (title.isNotEmpty) Text('Chức danh: $title'),
                                      Text('Khoa: $facultyName'),
                                      Text('Email: ${profile['email'] ?? 'Chưa có'}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive ? Icons.check_circle : Icons.cancel,
                                        color: isActive ? Colors.green : Colors.red,
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) => _handleMenuAction(value, teacher),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                                          ),
                                          const PopupMenuItem(value: 'delete', child: Text('Xóa')),
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

  Future<void> _toggleTeacherStatus(Map<String, dynamic> teacher) async {
    try {
      final newStatus = !(teacher['is_active'] ?? true);
      await Supabase.instance.client
          .from('profiles')
          .update({'is_active': newStatus})
          .eq('id', teacher['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Đã kích hoạt giáo viên' : 'Đã vô hiệu hóa giáo viên'),
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

    Future<void> _handleMenuAction(
    String action,
    Map<String, dynamic> teacher,
  ) async {
    switch (action) {
      case 'edit':
        await _navigateToEdit(teacher);
        break;
      case 'delete':
        await _confirmDelete(teacher);
        break;
    }
  }


  Future<void> _confirmDelete(Map<String, dynamic> teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa giáo viên "${teacher['full_name']}"?'),
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
        await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('id', teacher['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa giáo viên thành công')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa giáo viên: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
