
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/attendance_entity.dart';
import '../../../bloc/attendance/attendance_bloc.dart';
import '../../../bloc/attendance/attendance_event.dart';
import '../../../bloc/attendance/attendance_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Add/AddAttendancePage.dart';
import '../Edit/EditAttendancePage.dart';

class AdminAttendanceList extends StatefulWidget {
  const AdminAttendanceList({super.key});

  @override
  State<AdminAttendanceList> createState() => _AdminAttendanceListState();
}

class _AdminAttendanceListState extends State<AdminAttendanceList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(const LoadAttendances());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAttendances(String query) {
    context.read<AttendanceBloc>().add(FilterAttendances(query));
  }

  void _deleteAttendance(AttendanceEntity attendance) {
    context.read<AttendanceBloc>().add(DeleteAttendance(attendance.id));
  }

  Future<void> _showEditAttendancePage(AttendanceEntity attendance) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAttendancePage(attendance: attendance.toJson()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý điểm danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAttendancePage()),
            ),
          ),
        ],
      ),
      body: Column( children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Tìm kiếm điểm danh',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterAttendances,
          ),
        ),
        Expanded(child: AdminAttendanceList()),
      ],
      ),
    );
  }
}
