import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/dependency_injection.dart';
import '../../bloc/session_instance/session_instance_bloc.dart';
import '../../bloc/session_instance/session_instance_event.dart';
import 'List/AdminSessionInstanceList.dart';

class AdminSessionInstances extends StatelessWidget {
  const AdminSessionInstances({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionInstanceBloc>(
      create: (_) => sl<SessionInstanceBloc>()..add(const LoadSessionInstances()),
      child: const AdminSessionInstanceList(),
    );
  }
}
