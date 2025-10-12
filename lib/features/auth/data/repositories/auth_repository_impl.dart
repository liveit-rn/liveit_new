import 'package:logger/logger.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final Logger logger = Logger();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      logger.i('🌐 Repository: Sending register request to remote data source');
      final authResponseModel = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );

      logger.i(
        '✅ Repository: Got response from remote - User ID: ${authResponseModel.user.id}',
      );
      logger.d('💾 Repository: Storing access token locally');

      // Store token after successful registration
      await localDataSource.storeAccessToken(authResponseModel.accessToken);

      logger.d('🔄 Repository: Converting model to entity');
      final entity = authResponseModel.toEntity();

      logger.i('✅ Repository: Register completed successfully');
      return entity;
    } catch (e, stackTrace) {
      logger.e(
        '❌ Repository: Register failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final authResponseModel = await remoteDataSource.login(
      email: email,
      password: password,
    );

    // Store token after successful login
    await localDataSource.storeAccessToken(authResponseModel.accessToken);

    return authResponseModel.toEntity();
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    final usernameCheckModel = await remoteDataSource.checkUsernameAvailability(
      username,
    );
    return usernameCheckModel.available;
  }

  @override
  Future<User> claimUsername(String username) async {
    final token = await localDataSource.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final userModel = await remoteDataSource.claimUsername(username, token);
    return userModel.toEntity();
  }

  @override
  Future<User> getCurrentUser() async {
    final token = await localDataSource.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final userModel = await remoteDataSource.getCurrentUser(token);
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    final token = await localDataSource.getAccessToken();
    if (token != null) {
      try {
        await remoteDataSource.logout(token);
      } catch (e) {
        // Even if remote logout fails, remove local token
      }
    }

    await localDataSource.removeAccessToken();
  }

  @override
  Future<String?> getAccessToken() async {
    return await localDataSource.getAccessToken();
  }

  @override
  Future<void> storeAccessToken(String token) async {
    await localDataSource.storeAccessToken(token);
  }

  @override
  Future<void> removeAccessToken() async {
    await localDataSource.removeAccessToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await localDataSource.isAuthenticated();
  }
}
