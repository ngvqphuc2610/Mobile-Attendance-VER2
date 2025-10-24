import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/dependency_injection.dart';
import 'core/constants/app_theme.dart';
import 'core/config/router.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/student/student_bloc.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/student_repository.dart';
import 'package:smart_auth/smart_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🚀 App starting...");

  try {
    // Load environment variables (optional for backend URL)
    try {
      await dotenv.load(fileName: ".env");
      print("✅ Environment loaded");

      final smartAuth = SmartAuth.instance;
      final hash = await smartAuth.getAppSignature();
      print("📱 ANDROID_SMS_HASH = $hash");
    } catch (e) {
      print("⚠️ No .env file found, using default values");
    }

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
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(authRepository: getIt<AuthRepository>())
                ..add(AuthCheckRequested()),
        ),
        BlocProvider<StudentBloc>(
          create: (context) =>
              StudentBloc(repository: getIt<StudentRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Mobile Attendance',
        theme: AppTheme.lightTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
