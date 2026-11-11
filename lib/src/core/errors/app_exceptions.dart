/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  }) : super();

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// No internet connection
  factory NetworkException.noConnection() => const NetworkException(
        'No internet connection. Please check your network.',
        code: 'NO_CONNECTION',
      );

  /// Request timeout
  factory NetworkException.timeout() => const NetworkException(
        'Request timed out. Please try again.',
        code: 'TIMEOUT',
      );

  /// Server unreachable
  factory NetworkException.serverUnreachable() => const NetworkException(
        'Unable to reach server. Please try again later.',
        code: 'SERVER_UNREACHABLE',
      );

  /// Unknown network error
  factory NetworkException.unknown(dynamic error) => NetworkException(
        'Network error: ${error.toString()}',
        code: 'UNKNOWN',
        originalError: error,
      );
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// Invalid credentials
  factory AuthException.invalidCredentials() => const AuthException(
        'Invalid email or password.',
        code: 'INVALID_CREDENTIALS',
      );

  /// Account already exists
  factory AuthException.emailExists() => const AuthException(
        'An account with this email already exists.',
        code: 'EMAIL_EXISTS',
      );

  /// Token expired
  factory AuthException.tokenExpired() => const AuthException(
        'Session expired. Please log in again.',
        code: 'TOKEN_EXPIRED',
      );

  /// Token invalid
  factory AuthException.tokenInvalid() => const AuthException(
        'Invalid session. Please log in again.',
        code: 'TOKEN_INVALID',
      );

  /// Unauthorized
  factory AuthException.unauthorized() => const AuthException(
        'Unauthorized. Please log in.',
        code: 'UNAUTHORIZED',
      );

  /// Refresh token failed
  factory AuthException.refreshFailed() => const AuthException(
        'Failed to refresh session. Please log in again.',
        code: 'REFRESH_FAILED',
      );

  /// Unknown auth error
  factory AuthException.unknown(dynamic error) => AuthException(
        'Authentication error: ${error.toString()}',
        code: 'UNKNOWN',
        originalError: error,
      );
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.single(String field, String message) => ValidationException(
        message,
        code: 'VALIDATION_ERROR',
        fieldErrors: {field: [message]},
      );

  factory ValidationException.multiple(Map<String, List<String>> errors) => ValidationException(
        'Validation failed',
        code: 'VALIDATION_ERROR',
        fieldErrors: errors,
      );
}

/// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ServerException.internalError() => const ServerException(
        'Internal server error. Please try again later.',
        statusCode: 500,
        code: 'INTERNAL_ERROR',
      );

  factory ServerException.badGateway() => const ServerException(
        'Server temporarily unavailable. Please try again.',
        statusCode: 502,
        code: 'BAD_GATEWAY',
      );

  factory ServerException.serviceUnavailable() => const ServerException(
        'Service unavailable. Please try again later.',
        statusCode: 503,
        code: 'SERVICE_UNAVAILABLE',
      );

  factory ServerException.fromStatus(int statusCode, String message) => ServerException(
        message,
        statusCode: statusCode,
        code: 'HTTP_$statusCode',
      );
}

/// Storage exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.writeFailed(String key) => StorageException(
        'Failed to save $key',
        code: 'WRITE_FAILED',
      );

  factory StorageException.readFailed(String key) => StorageException(
        'Failed to read $key',
        code: 'READ_FAILED',
      );

  factory StorageException.deleteFailed(String key) => StorageException(
        'Failed to delete $key',
        code: 'DELETE_FAILED',
      );

  factory StorageException.unknown(dynamic error) => StorageException(
        'Storage error: ${error.toString()}',
        code: 'UNKNOWN',
        originalError: error,
      );
}

/// Unknown exception wrapper
class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.originalError,
    super.stackTrace,
  }) : super(code: 'UNKNOWN');

  static AppException from(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) return error;
    return UnknownException(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

/// Result type for handling success/failure
sealed class Result<T> {
  const Result();

  /// Handle both success and failure cases
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    switch (this) {
      case Success<T>(value: final v):
        return onSuccess(v);
      case Failure<T>(error: final e):
        return onFailure(e);
    }
  }

  /// Get value if success, otherwise throw
  T getOrThrow() {
    return fold(
      onSuccess: (v) => v,
      onFailure: (e) => throw e,
    );
  }

  /// Check if success
  bool get isSuccess => this is Success<T>;

  /// Check if failure
  bool get isFailure => this is Failure<T>;
}

/// Success case
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Failure case
class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}