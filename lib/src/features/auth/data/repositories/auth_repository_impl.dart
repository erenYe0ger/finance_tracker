import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

part 'auth_repository_impl.g.dart';

/// Auth repository implementation provider
@riverpod
AuthRepository authRepository(Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(remoteDataSource, storage);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<Result<domain.User>> register(String email, String password) async {
    try {
      final request = RegisterRequest(email: email.trim().toLowerCase(), password: password);
      return await _remoteDataSource.register(request);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException.from(e, StackTrace.current));
    }
  }

  @override
  Future<Result<domain.User>> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email.trim().toLowerCase(), password: password);
      final result = await _remoteDataSource.login(request);

      return await result.fold(
        onSuccess: (tokens) async {
          // Store tokens first
          await _storage.write(key: AppConstants.accessTokenKey, value: tokens.accessToken);
          await _storage.write(key: AppConstants.refreshTokenKey, value: tokens.refreshToken);

          // Fetch the profile with the token returned by login. This avoids
          // an immediate secure-storage read in the request interceptor.
          final userResult = await _remoteDataSource.getMe(
            accessToken: tokens.accessToken,
          );
          return await userResult.fold(
            onSuccess: (user) async {
              await _storage.write(key: AppConstants.userIdKey, value: user.id.toString());
              await _storage.write(key: AppConstants.userEmailKey, value: user.email);

              return Success(user);
            },
            onFailure: (error) => Failure(error),
          );
        },
        onFailure: (error) => Failure(error),
      );
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException.from(e, StackTrace.current));
    }
  }

  @override
  Future<Result<AuthTokens>> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        return Failure(AuthException.tokenInvalid());
      }

      final tokens = await _remoteDataSource.refreshToken(refreshToken);
      if (tokens == null) {
        await clearAuth();
        return Failure(AuthException.refreshFailed());
      }

      // Store new tokens
      await _storage.write(key: AppConstants.accessTokenKey, value: tokens.accessToken);
      await _storage.write(key: AppConstants.refreshTokenKey, value: tokens.refreshToken);

      return Success(AuthTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn,
      ));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException.from(e, StackTrace.current));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(refreshToken);
      }
      await clearAuth();
      return Success(null);
    } on AppException catch (e) {
      // Even if logout fails on server, clear local storage
      await clearAuth();
      return Failure(e);
    } catch (e) {
      await clearAuth();
      return Failure(UnknownException.from(e, StackTrace.current));
    }
  }

  @override
  Future<Result<domain.User>> getCurrentUser() async {
    try {
      final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
      if (accessToken == null || accessToken.isEmpty) {
        return Failure(AuthException.unauthorized());
      }

      // Token is in storage, interceptor will add it
      return await _remoteDataSource.getMe();
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException.from(e, StackTrace.current));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    return accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty;
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearAuth() async {
    await _storage.deleteAll();
  }
}
