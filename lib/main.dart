import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/dependency_injection.dart';
import 'core/constants/app_theme.dart';
import 'presentation/bloc/student/student_bloc.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/face_scan_page.dart';
import 'presentation/pages/barcode_scan_page.dart';
import 'data/repositories/student_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null ||
      supabaseAnonKey == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey.isEmpty) {
    throw Exception(
      'SUPABASE_URL or SUPABASE_ANON_KEY is missing or empty in .env',
    );
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Setup dependency injection
  await setupDependencyInjection();

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
      child: MaterialApp(
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
        initialRoute: Supabase.instance.client.auth.currentSession == null
            ? '/login'
            : '/home',
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/face_scan': (context) => const FaceScanPage(),
          '/barcode_scan': (context) => const BarcodeScanPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
