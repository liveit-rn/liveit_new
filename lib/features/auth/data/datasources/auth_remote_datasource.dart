import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../../core/config/app_config.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../models/username_check_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? name,
  });

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<UsernameCheckModel> checkUsernameAvailability(String username);

  Future<UserModel> claimUsername(String username, String token);

  Future<UserModel> getCurrentUser(String token);

  Future<void> logout(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final Logger logger = Logger();

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final url = '${AppConfig.apiBaseUrl}/auth/register';
      final requestData = {
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      };

      logger.i('🌐 Remote: Sending POST request to $url');
      logger.d('📋 Remote: Request data: $requestData');

      final response = await dio.post(url, data: requestData);

      logger.i('✅ Remote: Got response with status ${response.statusCode}');
      logger.d('📋 Remote: Response data: ${response.data}');

      final authResponseModel = AuthResponseModel.fromJson(response.data);
      logger.i('🔄 Remote: Parsed response model successfully');

      return authResponseModel;
    } on DioException catch (e) {
      logger.e('❌ Remote: DioException occurred', error: e);
      logger.e('📋 Remote: Response data: ${e.response?.data}');
      logger.e('📋 Remote: Status code: ${e.response?.statusCode}');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      logger.e(
        '❌ Remote: Unexpected error during register',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '${AppConfig.apiBaseUrl}/auth/login',
        data: {'email': email, 'password': password},
      );

      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UsernameCheckModel> checkUsernameAvailability(String username) async {
    try {
      final response = await dio.get(
        '${AppConfig.apiBaseUrl}/auth/username/check',
        queryParameters: {'username': username},
      );

      return UsernameCheckModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> claimUsername(String username, String token) async {
    try {
      final response = await dio.post(
        '${AppConfig.apiBaseUrl}/auth/claim-username',
        data: {'username': username},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    try {
      final response = await dio.get(
        '${AppConfig.apiBaseUrl}/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout(String token) async {
    try {
      await dio.post(
        '${AppConfig.apiBaseUrl}/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    logger.e('🚨 Error Handler: Processing DioException');

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;
      final message = responseData is Map
          ? (responseData['message'] ?? 'An error occurred')
          : 'An error occurred';

      logger.e('📋 Error Handler: Status $statusCode, Message: $message');
      logger.e('📋 Error Handler: Full response data: $responseData');

      switch (statusCode) {
        case 400:
          return Exception(message);
        case 401:
          return Exception('Invalid credentials');
        case 409:
          return Exception(message);
        case 500:
          return Exception('Server error. Please try again later.');
        default:
          return Exception('Network error. Please check your connection.');
      }
    } else {
      logger.e('📋 Error Handler: No response data - likely network issue');
      logger.e('📋 Error Handler: Error type: ${e.type}');
      logger.e('📋 Error Handler: Error message: ${e.message}');
      return Exception('Network error. Please check your connection.');
    }
  }
}
