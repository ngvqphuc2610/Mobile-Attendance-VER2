import 'package:get_it/get_it.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/attendance_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<StudentRepository>(() => StudentRepository());
  getIt.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository());
  
  print("✅ Dependencies registered");
}
