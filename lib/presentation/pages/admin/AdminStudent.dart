import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/class_model.dart';
import 'add/AddStudentPage.dart';
import 'edit/EditStudentPage.dart';

class AdminStudent extends StatefulWidget {
  const AdminStudent({super.key});

  @override
  State<AdminStudent> createState() => _AdminStudentState();
}

class _AdminStudentState extends State<AdminStudent> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;
  String? _error;
  String? _selectedFacultyFilter;
  String? _selectedClassFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final facultiesResponse = await Supabase.instance.client
          .from('faculties')
          .select('id, name')
          .order('name');

      final classesResponse = await Supabase.instance.client
          .from('classes')
          .select('id, name, faculty_id')
          .order('name');

      setState(() {
        _faculties = List<Map<String, dynamic>>.from(facultiesResponse);
        _classes = List<Map<String, dynamic>>.from(classesResponse);
      });
    } catch (e) {
      print('Error loading filters: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final studentsResponse = await Supabase.instance.client
          .from('students')
          .select('''
            *,
            profiles!inner (
              id,
              code,
              full_name,
              email,
              phone,
              is_active
            ),
            classes (
              id,
              name,
              faculty_id,
              faculties (
                id,
                name
              )
            )
          ''')
          .order('profiles(full_name)');

      _students = List<Map<String, dynamic>>.from(studentsResponse);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _students;

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((student) {
        final profile = student['profiles'] ?? {};
        final name = profile['full_name']?.toString().toLowerCase() ?? '';
        final code = profile['code']?.toString().toLowerCase() ?? '';
        final mssv = student['mssv']?.toString().toLowerCase() ?? '';
        final className =
            student['classes']?['name']?.toString().toLowerCase() ?? '';

        return name.contains(query) ||
            code.contains(query) ||
            mssv.contains(query) ||
            className.contains(query);
      }).toList();
    }

    // Filter by faculty
    if (_selectedFacultyFilter != null) {
      filtered = filtered.where((student) {
        return student['classes']?['faculty_id'] == _selectedFacultyFilter;
      }).toList();
    }

    // Filter by class
    if (_selectedClassFilter != null) {
      filtered = filtered.where((student) {
        return student['class_id'] == _selectedClassFilter;
      }).toList();
    }

    setState(() {
      _filteredStudents = filtered;
    });
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStudentPage()),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEdit(Map<String, dynamic> student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentPage(student: student),
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
        title: const Text('Quản lý Sinh viên'),
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
                hintText: 'Tìm kiếm sinh viên...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFacultyFilter,
                    decoration: const InputDecoration(
                      labelText: 'Khoa',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả khoa'),
                      ),
                      ..._faculties.map(
                        (faculty) => DropdownMenuItem(
                          value: faculty['id'],
                          child: Text(faculty['name']),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFacultyFilter = value;
                        _selectedClassFilter = null;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClassFilter,
                    decoration: const InputDecoration(
                      labelText: 'Lớp',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả lớp'),
                      ),
                      ..._classes
                          .where(
                            (cls) =>
                                _selectedFacultyFilter == null ||
                                cls['faculty_id'] == _selectedFacultyFilter,
                          )
                          .map(
                            (cls) => DropdownMenuItem(
                              value: cls['id'],
                              child: Text(cls['name']),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedClassFilter = value);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Lỗi: $_error'))
                : _filteredStudents.isEmpty
                ? const Center(child: Text('Không có sinh viên nào'))
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final profile = student['profiles'] ?? {};
                      final className =
                          student['classes']?['name'] ?? 'Chưa có lớp';
                      final facultyName =
                          student['classes']?['faculties']?['name'] ??
                          'Chưa có khoa';

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
                              if (student['mssv'] != null)
                                Text('MSSV: ${student['mssv']}'),
                              Text('Lớp: $className'),
                              Text('Khoa: $facultyName'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleMenuAction(value, student),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Sửa'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa'),
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

  Future<void> _handleMenuAction(
    String action,
    Map<String, dynamic> student,
  ) async {
    switch (action) {
      case 'edit':
        await _navigateToEdit(student);
        break;
      case 'delete':
        await _confirmDelete(student);
        break;
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
        await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('id', student['profile_id']);

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
