import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_username_availability_usecase.dart';
import '../../features/auth/domain/usecases/claim_username_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/habit_tracker/data/datasources/habit_remote_data_source.dart';
import '../../features/habit_tracker/data/repositories/habit_repository_impl.dart';
import '../../features/habit_tracker/domain/repositories/habit_repository.dart';
import '../../features/habit_tracker/presentation/bloc/habit_bloc.dart';
import '../../features/inspire/data/datasources/articles_public_remote_datasource.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Core
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // DioClient with interceptors
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(storage: getIt<FlutterSecureStorage>()),
  );

  // Legacy Dio for auth (will be migrated to DioClient)
  getIt.registerLazySingleton<Dio>(() => Dio());

  // Auth DataSources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt()),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(storage: getIt()),
  );

  // Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () =>
        AuthRepositoryImpl(remoteDataSource: getIt(), localDataSource: getIt()),
  );

  // Auth UseCases
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => CheckUsernameAvailabilityUseCase(getIt()));
  getIt.registerLazySingleton(() => ClaimUsernameUseCase(getIt()));

  // Profile DataSources (needed by AuthBloc for timezone sync)
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(dioClient: getIt<DioClient>()),
  );

  // Profile Repository
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt<ProfileRemoteDataSource>(),
    ),
  );

  // Auth BLoC
  getIt.registerFactory(
    () => AuthBloc(
      registerUseCase: getIt(),
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      checkUsernameAvailabilityUseCase: getIt(),
      claimUsernameUseCase: getIt(),
      authRepository: getIt(),
      profileRepository: getIt<ProfileRepository>(),
    ),
  );

  // Habit Tracker Feature
  getIt.registerLazySingleton<HabitRemoteDataSource>(
    () => HabitRemoteDataSourceImpl(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(remoteDataSource: getIt<HabitRemoteDataSource>()),
  );

  getIt.registerFactory<HabitBloc>(
    () => HabitBloc(repository: getIt<HabitRepository>()),
  );

  // Inspire / Articles (public)
  getIt.registerLazySingleton<ArticlesPublicRemoteDataSource>(
    () => ArticlesPublicRemoteDataSource(dioClient: getIt<DioClient>()),
  );
}
