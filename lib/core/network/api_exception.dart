/// Custom exception for API errors.
/// WHY: Provides typed exceptions with user-friendly error messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    required this.type,
    this.errors,
  });

  // Factory constructors for common error types
  factory ApiException.badRequest({required String message}) {
    return ApiException(
      message: message,
      statusCode: 400,
      type: ApiExceptionType.badRequest,
    );
  }

  factory ApiException.unauthorized({required String message}) {
    return ApiException(
      message: message,
      statusCode: 401,
      type: ApiExceptionType.unauthorized,
    );
  }

  factory ApiException.forbidden({required String message}) {
    return ApiException(
      message: message,
      statusCode: 403,
      type: ApiExceptionType.forbidden,
    );
  }

  factory ApiException.notFound({required String message}) {
    return ApiException(
      message: message,
      statusCode: 404,
      type: ApiExceptionType.notFound,
    );
  }

  factory ApiException.validationError({
    required String message,
    Map<String, dynamic>? errors,
  }) {
    return ApiException(
      message: message,
      statusCode: 422,
      type: ApiExceptionType.validationError,
      errors: errors,
    );
  }

  factory ApiException.serverError({required String message}) {
    return ApiException(
      message: message,
      statusCode: 500,
      type: ApiExceptionType.serverError,
    );
  }

  factory ApiException.timeout({required String message}) {
    return ApiException(message: message, type: ApiExceptionType.timeout);
  }

  factory ApiException.noInternet({required String message}) {
    return ApiException(message: message, type: ApiExceptionType.noInternet);
  }

  factory ApiException.cancelled({required String message}) {
    return ApiException(message: message, type: ApiExceptionType.cancelled);
  }

  factory ApiException.unknown({required String message}) {
    return ApiException(message: message, type: ApiExceptionType.unknown);
  }

  @override
  String toString() {
    return 'ApiException(type: $type, statusCode: $statusCode, message: $message)';
  }
}

enum ApiExceptionType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  validationError,
  serverError,
  timeout,
  noInternet,
  cancelled,
  unknown,
}
