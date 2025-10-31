import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../presentation/bloc/attendance/attendance_bloc.dart';
import '../../../presentation/bloc/attendance/attendance_event.dart';
import '../../../presentation/bloc/class_section/class_section_bloc.dart';
import '../../../presentation/bloc/class_section/class_section_event.dart';
import '../../../presentation/bloc/enrollment/enrollment_bloc.dart';
import '../../../presentation/bloc/enrollment/enrollment_event.dart';
import '../../../presentation/bloc/enrollment/enrollment_state.dart';
import '../../../presentation/bloc/session_instance/session_instance_bloc.dart';
import '../../../presentation/bloc/session_instance/session_instance_event.dart';
import 'StudentDetailClassPage.dart';

class StudentListClassPage extends StatefulWidget {
  final String studentId;

  const StudentListClassPage({super.key, required this.studentId});

  @override
  StudentListClassPageState createState() => StudentListClassPageState();
}

class StudentListClassPageState extends State<StudentListClassPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    context.read<EnrollmentBloc>().add(LoadEnrollmentsByStudent(widget.studentId));
  }

  void refresh() => _loadClasses();

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lop hoc phan'),
        actions: [
          IconButton(
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          if (state is EnrollmentLoading || state is EnrollmentInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EnrollmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is EnrollmentsLoaded) {
            if (state.enrollments.isEmpty) {
              return const Center(
                child: Text('Chưa đăng ký lớp học phần nào'),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.enrollments.length,
              itemBuilder: (context, index) {
                final enrollment = state.enrollments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(enrollment.section?.subject?.name ?? 'Chưa có tên môn'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mã lớp: ${enrollment.section?.sectionCode ?? 'N/A'}'),
                        Text('Học kỳ: ${enrollment.section?.semester ?? 'N/A'} - ${enrollment.section?.year ?? 'N/A'}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      final sectionId = enrollment.sectionId ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider<ClassSectionBloc>(
                                create: (_) =>
                                    sl<ClassSectionBloc>()..add(const LoadClassSections()),
                              ),
                              BlocProvider<SessionInstanceBloc>(
                                create: (_) => sl<SessionInstanceBloc>()
                                  ..add(LoadSessionInstances(sectionId: sectionId)),
                              ),
                              BlocProvider<AttendanceBloc>(
                                create: (_) => sl<AttendanceBloc>()
                                  ..add(
                                    LoadAttendances(
                                      userId: widget.studentId,
                                      sectionId: sectionId,
                                    ),
                                  ),
                              ),
                            ],
                            child: StudentDetailClassPage(
                              classSectionId: sectionId,
                              studentId: widget.studentId,
                            ),
                          ),
                        ),
                      );
                      // Navigate to class detail if needed
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}


