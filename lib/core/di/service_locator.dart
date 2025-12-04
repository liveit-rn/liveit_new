import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/habit_tracker/data/datasources/habit_remote_data_source.dart';
import '../../features/habit_tracker/data/repositories/habit_repository_impl.dart';
import '../../features/habit_tracker/domain/repositories/habit_repository.dart';
import '../../features/habit_tracker/presentation/bloc/habit_bloc.dart';

final getIt = GetIt.instance;

/// Setup dependency injection.
/// WHY: Centralized service locator for managing dependencies.
Future<void> setupDependencyInjection() async {
  // Core
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<DioClient>(
    () => DioClient(storage: getIt<FlutterSecureStorage>()),
  );

  // Profile Feature
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(dioClient: getIt<DioClient>()),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt<ProfileRemoteDataSource>(),
    ),
  );

  // Habit Feature
  getIt.registerLazySingleton<HabitRemoteDataSource>(
    () => HabitRemoteDataSourceImpl(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(
      remoteDataSource: getIt<HabitRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<HabitBloc>(
    () => HabitBloc(repository: getIt<HabitRepository>()),
  );
}
