import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/di/dependency_injection.dart';
import '../../bloc/enrollment/enrollment_bloc.dart';
import '../../bloc/enrollment/enrollment_event.dart';
import 'List/AdminEnrollmentList.dart';

class AdminEnrollments extends StatelessWidget {
  const AdminEnrollments({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EnrollmentBloc>(
      create: (_) => sl<EnrollmentBloc>()..add(const LoadEnrollments()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý đăng ký học phần'),
          backgroundColor: AppTheme.adminPrimaryColor,
        ),
        body: const AdminEnrollmentList(),
      ),
    );
  }
}
