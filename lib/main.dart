import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/dependency_injection.dart';
import 'core/constants/app_theme.dart';
import 'presentation/bloc/student/student_bloc.dart';
import 'package:go_router/go_router.dart';
import 'presentation/pages/login_page.dart';
import 'data/repositories/student_repository.dart';

import 'core/config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🚀 App starting...");
  
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Environment loaded");
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    print("🔗 Supabase URL: $supabaseUrl");
    
    await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseAnonKey!);
    print("✅ Supabase initialized");
    
    await setupDependencyInjection();
    print("✅ DI setup complete");
    
  } catch (e) {
    print("❌ Error in main: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => StudentBloc(getIt<StudentRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Mobile Attendance',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingMedium,
            ),
          ),
        ),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
