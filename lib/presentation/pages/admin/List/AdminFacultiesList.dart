
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/faculty_entity.dart';
import '../../../bloc/faculty/faculty_bloc.dart';
import '../../../bloc/faculty/faculty_event.dart';
import '../../../bloc/faculty/faculty_state.dart';
import '../../../widgets/loading_widget.dart';

class AdminFacultiesList extends StatefulWidget {
  const AdminFacultiesList({Key? key}) : super(key: key);

  @override
  _AdminFacultiesListState createState() => _AdminFacultiesListState();
}

class _AdminFacultiesListState extends State<AdminFacultiesList> {
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

  void _filterFaculties(String query) {
    context.read<FacultyBloc>().add(FilterFaculties(query));
  }

  void _deleteFaculty(FacultyEntity faculty) {
    context.read<FacultyBloc>().add(DeleteFaculty(faculty.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FacultyBloc, FacultyState>(
      builder: (context, state) {
        if (state is FacultyLoading) {
          return const LoadingWidget(message: 'Đang tải khoa...');
        } else if (state is FacultyError) {
          return Center(
            child: Text('Lỗi: ${state.message}'),
          );
        } else if (state is FacultiesLoaded) {
          final faculties = state.filteredFaculties;
          if (faculties.isEmpty) {
            return const Center(
              child: Text('Chưa có khoa nào'),
            );
          }
          return ListView.builder(
            itemCount: faculties.length,
            itemBuilder: (context, index) {
              final faculty = faculties[index];
              return ListTile(
                title: Text(faculty.name),
                subtitle: Text('Mã khoa: ${faculty.code}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteFaculty(faculty),
                ),
              );
            },
          );
        } else {
          return const Center(
            child: Text('Không có dữ liệu'),
          );
        }
      },
    );
  }
}
