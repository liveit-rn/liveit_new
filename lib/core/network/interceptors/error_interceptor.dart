import 'package:dio/dio.dart';
import '../api_exception.dart';

/// Error interceptor to handle and transform API errors.
/// WHY: Converts Dio exceptions to app-specific exceptions with user-friendly messages.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = ApiException.timeout(
          message: 'Koneksi timeout. Silakan coba lagi.',
        );
        break;

      case DioExceptionType.badResponse:
        apiException = _handleHttpError(err.response);
        break;

      case DioExceptionType.cancel:
        apiException = ApiException.cancelled(message: 'Request dibatalkan.');
        break;

      case DioExceptionType.connectionError:
        apiException = ApiException.noInternet(
          message: 'Tidak ada koneksi internet. Periksa koneksi Anda.',
        );
        break;

      default:
        apiException = ApiException.unknown(
          message: 'Terjadi kesalahan. Silakan coba lagi.',
        );
    }

    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        type: err.type,
        response: err.response,
      ),
    );
  }

  ApiException _handleHttpError(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    // Extract error message from response
    String message = 'Terjadi kesalahan pada server.';
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    }

    switch (statusCode) {
      case 400:
        return ApiException.badRequest(message: message);
      case 401:
        return ApiException.unauthorized(
          message: 'Sesi Anda telah berakhir. Silakan login kembali.',
        );
      case 403:
        return ApiException.forbidden(message: 'Anda tidak memiliki akses.');
      case 404:
        return ApiException.notFound(message: 'Data tidak ditemukan.');
      case 422:
        return ApiException.validationError(
          message: message,
          errors: data is Map ? data['errors'] : null,
        );
      case 500:
      case 502:
      case 503:
        return ApiException.serverError(
          message: 'Server sedang bermasalah. Silakan coba lagi nanti.',
        );
      default:
        return ApiException.unknown(message: message);
    }
  }
}
