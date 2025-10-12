import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

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

final getIt = GetIt.instance;

void configureDependencies() {
  // Core
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

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

  // Auth BLoC
  getIt.registerFactory(
    () => AuthBloc(
      registerUseCase: getIt(),
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      checkUsernameAvailabilityUseCase: getIt(),
      claimUsernameUseCase: getIt(),
      authRepository: getIt(),
    ),
  );
}
