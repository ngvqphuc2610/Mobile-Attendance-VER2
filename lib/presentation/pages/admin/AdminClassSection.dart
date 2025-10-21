import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/class_section_repository.dart';
import '../../bloc/class_section/class_section_bloc.dart';
import 'List/AdminClassSectionList.dart';

class AdminClassSection extends StatelessWidget {
  const AdminClassSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassSectionBloc>(
      // đúng tên tham số: classSectionRepository
      create: (_) => ClassSectionBloc(
        classSectionRepository: ClassSectionRepositoryImpl(),
      ),
      lazy: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lớp học phần'),
        ),
        body: const AdminClassSectionList(), // TextField giờ có Scaffold bao quanh
      ),
    );
  }
}
