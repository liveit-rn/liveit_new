import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';

void main() async {
  await dotenv.load(fileName: '.env.prod'); // Load .env.prod file
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Router aplikasi berbasis auto_route
  static final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LIVEIT',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // Gunakan konfigurasi router dari auto_route.
      routerConfig: _appRouter.config(),
    );
  }
}
