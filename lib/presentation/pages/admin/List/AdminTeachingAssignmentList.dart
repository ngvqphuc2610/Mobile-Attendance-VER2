
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/teaching_assignment_model.dart';
import '../../../bloc/teaching_assignment/teaching_assignment_bloc.dart';
import '../../../bloc/teaching_assignment/teaching_assignment_event.dart';
import '../../../bloc/teaching_assignment/teaching_assignment_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Edit/EditTeachingAssignmentPage.dart';
import '../Add/AddTeachingAssignmentPage.dart';

class AdminTeachingAssignmentList extends StatefulWidget {
  const AdminTeachingAssignmentList({Key? key}) : super(key: key);

  @override
  _AdminTeachingAssignmentListState createState() => _AdminTeachingAssignmentListState();
}

class _AdminTeachingAssignmentListState extends State<AdminTeachingAssignmentList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAssignments(String query) {
    context.read<TeachingAssignmentBloc>().add(FilterTeachingAssignments(query));
  }

  void _deleteAssignment(TeachingAssignmentModel assignment) {
    context.read<TeachingAssignmentBloc>().add(
      DeleteTeachingAssignment(
        '${assignment.sectionId}|${assignment.teacherId}',
      ),
    );
  }

  Future<void> _showEditAssignmentPage(TeachingAssignmentModel assignment) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTeachingAssignmentPage(assignment: assignment.toJson()),
      ),
    );

    if (updated == true && mounted) {
      context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phân công giảng dạy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTeachingAssignmentPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm theo section, giáo viên hoặc vai trò...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onChanged: _filterAssignments,
            ),
          ),
          Expanded(child: AdminTeachingAssignmentList()),
        ],
      ),
    );
  }
}
