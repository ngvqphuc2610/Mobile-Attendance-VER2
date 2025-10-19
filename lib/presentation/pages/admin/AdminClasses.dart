import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../bloc/class/class_bloc.dart';
import '../../bloc/class/class_event.dart';
import 'List/AdminClassList.dart';

class AdminClasses extends StatefulWidget {
  const AdminClasses({super.key});

  @override
  State<AdminClasses> createState() => _AdminClassesState();
}

class _AdminClassesState extends State<AdminClasses> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load sau frame đầu tiên để chắc chắn đã có BLoC (nếu cung cấp ở trên)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClassBloc>().add(const LoadClasses());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<ClassBloc>().add(FilterClasses(q.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý lớp')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm lớp',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const Expanded(child: AdminClassList()),
        ],
      ),
    );
  }
}
