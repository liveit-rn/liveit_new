import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liveit_new/core/router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:liveit_new/core/theme/app_theme.dart';
import 'package:liveit_new/core/injection/injection_container.dart';
import 'package:liveit_new/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:liveit_new/features/auth/presentation/bloc/auth_event.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_bloc.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_event.dart';
import 'package:liveit_new/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:liveit_new/features/profile/presentation/bloc/profile_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.prod'); // Load .env.prod file
  await initializeDateFormatting('id_ID', null); // Initialize Indonesian locale

  // Initialize Hive for local caching (Safe, Singleton-pattern)
  await Hive.initFlutter();

  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Router aplikasi berbasis auto_route
  static final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<HabitBloc>(
          create: (context) => getIt<HabitBloc>()..add(HabitStarted()),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => getIt<ProfileBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'LIVEIT',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        // Gunakan konfigurasi router dari auto_route.
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
