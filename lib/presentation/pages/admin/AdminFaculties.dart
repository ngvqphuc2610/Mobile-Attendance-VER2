import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../widgets/loading_widget.dart';
import 'edit/EditFacultyPage.dart';
import 'add/AddFacultyPage.dart';
import 'List/AdminFacultiesList.dart';
import '../../../data/models/entity/faculty_entity.dart';
import '../../bloc/faculty/faculty_bloc.dart';
import '../../bloc/faculty/faculty_event.dart';

class AdminFaculties extends StatefulWidget {
  const AdminFaculties({super.key});

  @override
  State<AdminFaculties> createState() => _AdminFacultiesState();
}

class _AdminFacultiesState extends State<AdminFaculties> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FacultyBloc>().add(const LoadFaculties());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddFacultyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFacultyPage()),
    );
  }

  void _showEditFacultyPage(FacultyEntity faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFacultyPage(faculty: faculty),
      ),
    );
  }

  void _showDeleteDialog(FacultyEntity faculty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khoa "${faculty.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<FacultyBloc>().add(DeleteFaculty(faculty.id));
            },
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
        title: const Text('Quản lý khoa'),
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
                      hintText: 'Tìm theo tên khoa...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                      ),
                    ),
                    onChanged: (query) {
                      context.read<FacultyBloc>().add(FilterFaculties(query));
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                ElevatedButton.icon(
                  onPressed: () => _showAddFacultyPage(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm khoa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: AdminFacultiesList()),
        ],
      ),
    );
  }
}
