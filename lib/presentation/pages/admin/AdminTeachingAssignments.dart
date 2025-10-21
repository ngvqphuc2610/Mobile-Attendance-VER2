import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/di/dependency_injection.dart';
import '../../bloc/class_section/class_section_bloc.dart';
import '../../bloc/class_section/class_section_event.dart';
import '../../bloc/teacher/teacher_bloc.dart';
import '../../bloc/teacher/teacher_event.dart';
import '../../bloc/teaching_assignment/teaching_assignment_bloc.dart';
import '../../bloc/teaching_assignment/teaching_assignment_event.dart';
import './List/AdminTeachingAssignmentList.dart';

class AdminTeachingAssignments extends StatelessWidget {
  const AdminTeachingAssignments({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TeachingAssignmentBloc>(
          create: (_) =>
              sl<TeachingAssignmentBloc>()..add(const LoadTeachingAssignments()),
          lazy: false,
        ),
        BlocProvider<ClassSectionBloc>(
          create: (_) => sl<ClassSectionBloc>()..add(const LoadClassSections()),
          lazy: false,
        ),
        BlocProvider<TeacherBloc>(
          create: (_) => sl<TeacherBloc>()..add(const LoadTeachers()),
          lazy: false,
        ),
      ],
      child: const _AdminTeachingAssignmentsView(),
    );
  }
}

class _AdminTeachingAssignmentsView extends StatelessWidget {
  const _AdminTeachingAssignmentsView();

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
