import 'package:get_it/get_it.dart';

import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/section_schedule_repository.dart';
import '../../data/repositories/session_instance_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../data/repositories/teaching_assignment_repository.dart';
import '../../presentation/bloc/attendance/attendance_bloc.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/class/class_bloc.dart';
import '../../presentation/bloc/section_schedule/section_schedule_bloc.dart';
import '../../presentation/bloc/session_instance/session_instance_bloc.dart';
import '../../presentation/bloc/student/student_bloc.dart';
import '../../presentation/bloc/teacher/teacher_bloc.dart';
import '../../presentation/bloc/teaching_assignment/teaching_assignment_bloc.dart';

final GetIt getIt = GetIt.instance;
final GetIt sl = getIt;

Future<void> setupDependencyInjection() async {
  if (getIt.isRegistered<AuthRepository>()) {
    return;
  }

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<StudentRepository>(() => StudentRepositoryImpl());
  getIt.registerLazySingleton<TeacherRepository>(() => TeacherRepositoryImpl());
  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(),
  );
  getIt.registerLazySingleton<ClassRepository>(() => ClassRepositoryImpl());
  getIt.registerLazySingleton<TeachingAssignmentRepository>(
    () => TeachingAssignmentRepository(),
  );
  getIt.registerLazySingleton<SessionInstanceRepository>(
    () => SessionInstanceRepository(),
  );
  getIt.registerLazySingleton<SectionScheduleRepository>(
    () => SectionScheduleRepository(),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authRepository: getIt()));
  getIt.registerFactory<StudentBloc>(() => StudentBloc(repository: getIt()));
  getIt.registerFactory<TeacherBloc>(() => TeacherBloc(repository: getIt()));
  getIt.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(repository: getIt()),
  );
  getIt.registerFactory<ClassBloc>(
    () => ClassBloc(classRepository: getIt<ClassRepository>()),
  );
  getIt.registerFactory<TeachingAssignmentBloc>(
    () => TeachingAssignmentBloc(repository: getIt()),
  );
  getIt.registerFactory<SessionInstanceBloc>(
    () => SessionInstanceBloc(repository: getIt()),
  );
  getIt.registerFactory<SectionScheduleBloc>(
    () => SectionScheduleBloc(repository: getIt()),
  );
}
