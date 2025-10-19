import 'dependency_injection.dart';

export 'dependency_injection.dart' show getIt, setupDependencyInjection, sl;

@Deprecated('Use setupDependencyInjection instead')
Future<void> init() async {
  await setupDependencyInjection();
  print('DI setup complete');
  
}
