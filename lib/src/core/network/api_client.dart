import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

part 'api_client.g.dart';

/// Dio instance provider
@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBasePath,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  // Add interceptors
  dio.interceptors.addAll([
    _AuthInterceptor(ref),
    _LoggingInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
}

/// Secure storage provider
@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences is enabled by default in newer versions
    ),
    // iOS options removed - Android-only app
  );
}

// Auth state notifier is defined in auth_provider.dart

/// Auth interceptor - adds access token and handles refresh
class _AuthInterceptor extends Interceptor {
  final Ref _ref;
  bool _isRefreshing = false;
  final List<Completer<void>> _waitingRequests = [];

  _AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Login can provide the token directly for the immediate profile fetch.
    // Avoid a secure-storage read when an Authorization header is already set.
    if (options.headers.containsKey('Authorization')) {
      return handler.next(options);
    }

    // Skip auth for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    final storage = _ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: AppConstants.accessTokenKey);

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 errors on non-public endpoints
    if (err.response?.statusCode == 401 && !_isPublicEndpoint(err.requestOptions.path)) {
      final refreshed = await _handleTokenRefresh(err.requestOptions);
      if (refreshed) {
        // Retry the original request
        final storage = _ref.read(secureStorageProvider);
        final newAccessToken = await storage.read(key: AppConstants.accessTokenKey);
        if (newAccessToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final response = await _ref.read(dioProvider).fetch(err.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(err);
          }
        }
      }
      // Refresh failed - clear auth and redirect to login
      await _clearAuthAndNotify();
    }
    return handler.next(err);
  }

  bool _isPublicEndpoint(String path) {
    final publicPaths = [
      AppConstants.registerEndpoint,
      AppConstants.loginEndpoint,
      AppConstants.refreshEndpoint,
      AppConstants.healthEndpoint,
    ];
    return publicPaths.any((p) => path.endsWith(p));
  }

  Future<bool> _handleTokenRefresh(RequestOptions originalRequest) async {
    // If already refreshing, wait for it to complete
    if (_isRefreshing) {
      final completer = Completer<void>();
      _waitingRequests.add(completer);
      try {
        await completer.future;
        return true;
      } catch (_) {
        return false;
      }
    }

    _isRefreshing = true;

    try {
      final storage = _ref.read(secureStorageProvider);
      final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Create a clean Dio instance for refresh (avoid interceptor loop)
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBasePath,
          connectTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        AppConstants.refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await storage.write(key: AppConstants.accessTokenKey, value: data['access_token']);
        await storage.write(key: AppConstants.refreshTokenKey, value: data['refresh_token']);

        // Notify waiting requests
        for (final completer in _waitingRequests) {
          completer.complete();
        }
        _waitingRequests.clear();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
      // Reject waiting requests if refresh failed
      for (final completer in _waitingRequests) {
        completer.completeError(Exception('Token refresh failed'));
      }
      _waitingRequests.clear();
    }
  }

  Future<void> _clearAuthAndNotify() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.deleteAll();
    // AuthNotifier will listen to storage changes or we can use a stream
    // For now, the next app start will handle unauthenticated state
  }
}

/// Logging interceptor for debug builds
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Debug logging
    // debugPrint('🌐 REQUEST[${options.method}] ${options.uri}');
    // debugPrint('Headers: ${options.headers}');
    // if (options.data != null) debugPrint('Body: ${options.data}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // debugPrint('✅ RESPONSE[${response.statusCode}] ${response.requestOptions.uri}');
    // debugPrint('Data: ${response.data}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // debugPrint('❌ ERROR[${err.response?.statusCode}] ${err.requestOptions.uri}');
    // debugPrint('Message: ${err.message}');
    // if (err.response?.data != null) debugPrint('Error Data: ${err.response?.data}');
    return handler.next(err);
  }
}

/// Error interceptor - converts DioException to AppException
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException.timeout();
        break;
      case DioExceptionType.connectionError:
        exception = NetworkException.noConnection();
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final data = err.response?.data;

        if (statusCode == 401) {
          exception = AuthException.unauthorized();
        } else if (statusCode == 403) {
          exception = AuthException.tokenInvalid();
        } else if (statusCode == 409) {
          exception = AuthException.emailExists();
        } else if (statusCode == 422 && data is Map) {
          // Validation errors
          final errors = <String, List<String>>{};
          if (data['detail'] is List) {
            for (final e in data['detail'] as List) {
              if (e is Map && e['loc'] is List && e['msg'] is String) {
                final field = (e['loc'] as List).last.toString();
                errors.putIfAbsent(field, () => []).add(e['msg'] as String);
              }
            }
          }
          if (errors.isNotEmpty) {
            exception = ValidationException.multiple(errors);
          } else {
            exception = ServerException.fromStatus(statusCode, data['detail']?.toString() ?? 'Validation error');
          }
        } else if (statusCode >= 500) {
          exception = ServerException.fromStatus(statusCode, data?['detail']?.toString() ?? 'Server error');
        } else {
          exception = ServerException.fromStatus(statusCode, data?['detail']?.toString() ?? 'Request failed');
        }
        break;
      case DioExceptionType.cancel:
        exception = NetworkException('Request cancelled', code: 'CANCELLED');
        break;
      case DioExceptionType.unknown:
      default:
        exception = NetworkException.unknown(err);
        break;
    }

    return handler.next(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      response: err.response,
      type: err.type,
    ));
  }
}
