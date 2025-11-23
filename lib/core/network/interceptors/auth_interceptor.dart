import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Auth interceptor to add JWT token to requests.
/// WHY: Automatically adds authorization header to all API requests.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor({required FlutterSecureStorage storage}) : _storage = storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from secure storage
    final token = await _storage.read(key: 'access_token');

    if (token != null && token.isNotEmpty) {
      // Add token to headers
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh logic here
      // For now, just clear the token
      _storage.delete(key: 'access_token');
    }

    return handler.next(err);
  }
}
