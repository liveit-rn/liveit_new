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
import 'package:logger/logger.dart';

final Logger logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/.env.prod');
    logger.i('✅ .env.prod loaded successfully');
    logger.i(
      '🔗 API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? "https://liveit-api-dev-5jufu.ondigitalocean.app"}',
    );
  } catch (e) {
    logger.e('❌ Failed to load .env.prod: $e');
  }

  await initializeDateFormatting('id_ID', null);

  await Hive.initFlutter();

  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        BlocProvider<ProfileBloc>(create: (context) => getIt<ProfileBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final apiUrl = dotenv.env['API_BASE_URL'] ?? 'https://liveit-api-dev-5jufu.ondigitalocean.app';

          // Debug: Show API URL on first launch
          logger.i('🔗 API_BASE_URL: $apiUrl');

          return MaterialApp.router(
            title: 'LIVEIT',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            routerConfig: _appRouter.config(),
          );
        },
      ),
    );
  }
}
