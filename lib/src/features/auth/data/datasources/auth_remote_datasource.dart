import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart' as domain;
import '../models/auth_models.dart';

part 'auth_remote_datasource.g.dart';

/// Remote data source for auth operations
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
}

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  /// Register a new user
  Future<Result<domain.User>> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final user = SafeUser.fromJson(response.data);
        return Success(domain.User(
          id: user.id,
          email: user.email,
          createdAt: user.createdAt,
        ));
      } else if (response.statusCode == 409) {
        return const Failure(AuthException(
          'An account with this email already exists',
          code: 'EMAIL_EXISTS',
        ));
      } else {
        return Failure(AuthException(
          response.data['detail']?.toString() ?? 'Registration failed',
          code: 'REGISTRATION_FAILED',
        ));
      }
    } on DioException catch (e) {
      if (e.error is AppException) rethrow;
      throw AuthException.unknown(e);
    }
  }

  /// Login user
  Future<Result<TokenPair>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final tokens = TokenPair.fromJson(response.data);
        return Success(tokens);
      } else if (response.statusCode == 401) {
        return const Failure(AuthException(
          'Invalid email or password',
          code: 'INVALID_CREDENTIALS',
        ));
      } else {
        return Failure(AuthException(
          response.data['detail']?.toString() ?? 'Login failed',
          code: 'LOGIN_FAILED',
        ));
      }
    } on DioException catch (e) {
      if (e.error is AppException) rethrow;
      throw AuthException.unknown(e);
    }
  }

  /// Refresh access token
  Future<TokenPair?> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        AppConstants.refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        return TokenPair.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Logout user
  Future<bool> logout(String refreshToken) async {
    try {
      final response = await _dio.post(
        AppConstants.logoutEndpoint,
        data: {'refresh_token': refreshToken},
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Get current user profile
  Future<Result<domain.User>> _getMe({String? accessToken}) async {
    try {
      // During login, use the just-issued token; otherwise the interceptor
      // obtains the saved token for regular profile refreshes.
      final response = await _dio.get(
        AppConstants.meEndpoint,
        options: accessToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final safeUser = SafeUser.fromJson(response.data);
        return Success(domain.User(
          id: safeUser.id,
          email: safeUser.email,
          createdAt: safeUser.createdAt,
        ));
      } else if (response.statusCode == 401) {
        return Failure(AuthException.tokenExpired());
      } else {
        return Failure(ServerException.fromStatus(
          response.statusCode ?? 0,
          response.data['detail']?.toString() ?? 'Failed to get user',
        ));
      }
    } on DioException catch (e) {
      if (e.error is AppException) {
        return Failure(e.error as AppException);
      }
      return Failure(AuthException.unknown(e));
    }
  }

  /// Get user profile (public method) - token read from storage by interceptor
  Future<Result<domain.User>> getMe({String? accessToken}) =>
      _getMe(accessToken: accessToken);

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get(AppConstants.healthEndpoint);
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
