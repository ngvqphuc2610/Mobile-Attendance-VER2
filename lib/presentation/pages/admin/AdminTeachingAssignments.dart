import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/teaching_assignment_model.dart';
import '../../bloc/teaching_assignment/teaching_assignment_bloc.dart';
import '../../bloc/teaching_assignment/teaching_assignment_event.dart';
import '../../bloc/teaching_assignment/teaching_assignment_state.dart';
import '../../widgets/loading_widget.dart'; 
import './List/AdminTeachingAssignmentList.dart';


class AdminTeachingAssignments extends StatefulWidget {
  const AdminTeachingAssignments({Key? key}) : super(key: key);

  @override
  _AdminTeachingAssignmentsState createState() => _AdminTeachingAssignmentsState();
}

class _AdminTeachingAssignmentsState extends State<AdminTeachingAssignments> {
  @override
  void initState() {
    super.initState();
    context.read<TeachingAssignmentBloc>().add(const LoadTeachingAssignments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phân công giảng dạy'),
        backgroundColor: AppTheme.adminPrimaryColor,
      ),
      body: const AdminTeachingAssignmentList(),
    );
  }
}
