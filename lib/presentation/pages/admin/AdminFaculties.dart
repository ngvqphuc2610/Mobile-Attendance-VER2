import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/faculty.dart';
import 'add/AddFacultyPage.dart';
import 'edit/EditFacultyPage.dart';

class AdminFaculties extends StatefulWidget {
  const AdminFaculties({super.key});

  @override
  State<AdminFaculties> createState() => _AdminFacultiesState();
}

class _AdminFacultiesState extends State<AdminFaculties> {
  final _searchController = TextEditingController();
  List<Faculty> _faculties = [];
  List<Faculty> _filteredFaculties = [];
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
      final response = await Supabase.instance.client
          .from('faculties')
          .select()
          .order('name');

      _faculties = (response as List)
          .map((json) => Faculty.fromJson(json))
          .toList();
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
        _filteredFaculties = _faculties
            .where((faculty) =>
                faculty.name.toLowerCase().contains(query.toLowerCase()) ||
                faculty.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFacultyPage()),
    );
    
    if (result == true) {
      _loadFaculties();
    }
  }

  Future<void> _navigateToEdit(Faculty faculty) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFacultyPage(faculty: faculty),
      ),
    );
    
    if (result == true) {
      _loadFaculties();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Khoa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAdd,
          ),
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
                hintText: 'Tìm kiếm khoa (tên, mã)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterFaculties,
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Lỗi: $_error'),
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
                            itemCount: _filteredFaculties.length,
                            itemBuilder: (context, index) {
                              final faculty = _filteredFaculties[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingMedium,
                                  vertical: AppSizes.paddingSmall,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      faculty.code.isNotEmpty
                                          ? faculty.code[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    faculty.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('Mã khoa: ${faculty.code}'),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
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
                                            Text('Xóa', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _navigateToEdit(faculty);
                                      } else if (value == 'delete') {
                                        _confirmDelete(faculty);
                                      }
                                    },
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

  Future<void> _confirmDelete(Faculty faculty) async {
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
        await Supabase.instance.client
            .from('faculties')
            .delete()
            .eq('id', faculty.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa khoa thành công')),
        );
        _loadFaculties();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa khoa: $e')),
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


