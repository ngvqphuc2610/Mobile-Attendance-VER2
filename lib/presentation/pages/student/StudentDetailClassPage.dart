// chi tiết lớp học phần của sinh viên
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/class_section/class_section_bloc.dart';
import '../../bloc/class_section/class_section_event.dart';
import '../../bloc/class_section/class_section_state.dart';
import '../../../data/models/entity/class_section_entity.dart';

class StudentDetailClassPage extends StatelessWidget {
  final String classSectionId;
  const StudentDetailClassPage({super.key, required this.classSectionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lớp học phần'),
      ),
      body: BlocBuilder<ClassSectionBloc, ClassSectionState>(
        builder: (context, state) {
          if (state is ClassSectionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClassSectionError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lỗi: ${state.message}'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.read<ClassSectionBloc>().add(const LoadClassSections()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is ClassSectionsLoaded) {
            final section = state.sections.firstWhere(
              (item) => item.id == classSectionId,
              orElse: () => const ClassSectionEntity(
                id: '',
                subjectId: '',
                semester: 0,
                year: 0,
                sectionCode: '',
              ),
            );

            if (section.id.isEmpty) {
              return const Center(child: Text('Không tìm thấy lớp học phần'));
            }

            return _ClassDetailView(section: section);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ClassDetailView extends StatelessWidget {
  final ClassSectionEntity section;
  const _ClassDetailView({required this.section});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.sectionCode ?? 'Lop hoc phan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (section.subject?.name != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    section.subject!.name!,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
                if (section.semester != null || section.year != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'HK ${section.semester ?? '-'} nam ${section.year ?? '-'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
