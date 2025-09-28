import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/supabase_datasource.dart';
import '../../data/repositories/student_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Supabase Client
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Data Sources
  getIt.registerSingleton<SupabaseDataSource>(
    SupabaseDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerSingleton<StudentRepository>(
    StudentRepositoryImpl(getIt<SupabaseDataSource>()),
  );
}
