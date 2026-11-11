import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_provider.g.dart';

/// Current auth state provider
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.initial);
  }

  /// Initialize auth state on app start - non-blocking, shows login immediately
  Future<void> initialize() async {
    // Start as unauthenticated immediately - don't block UI
    state = const AuthState(status: AuthStatus.unauthenticated);

    // Check for stored tokens in background
    _checkStoredTokens();
  }

  /// Check for stored tokens and validate them in background
  Future<void> _checkStoredTokens() async {
    final repository = ref.read(authRepositoryProvider);

    // Quick check for stored tokens (fast local storage read)
    bool hasTokens = false;
    try {
      hasTokens = await repository.isLoggedIn().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
    } catch (_) {
      hasTokens = false;
    }

    if (!hasTokens) {
      // No tokens stored, stay unauthenticated
      return;
    }

    // Tokens exist, try to validate them in background
    // Don't set loading state - just update when done
    try {
      final result = await repository.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Failure(NetworkException.timeout()),
      );
      result.fold(
        onSuccess: (user) {
          // Valid session found
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
          );
        },
        onFailure: (error) {
          // Token expired or invalid, try refresh
          _tryRefreshAndGetUser();
        },
      );
    } catch (_) {
      // Network error, stay unauthenticated
      // User can still login manually
    }
  }

  /// Try to refresh token and get user
  Future<void> _tryRefreshAndGetUser() async {
    final repository = ref.read(authRepositoryProvider);

    // Add timeout to prevent hanging
    late Result<AuthTokens> refreshResult;
    try {
      refreshResult = await repository.refreshToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Failure(NetworkException.timeout()),
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    refreshResult.fold(
      onSuccess: (tokens) async {
        // Refresh succeeded, try get user again
        late Result<User> userResult;
        try {
          userResult = await repository.getCurrentUser().timeout(
            const Duration(seconds: 5),
            onTimeout: () => Failure(NetworkException.timeout()),
          );
        } catch (_) {
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }

        userResult.fold(
          onSuccess: (user) {
            state = AuthState(
              status: AuthStatus.authenticated,
              user: user,
            );
          },
          onFailure: (error) {
            state = const AuthState(status: AuthStatus.unauthenticated);
          },
        );
      },
      onFailure: (error) {
        // Refresh failed, user needs to login
        state = const AuthState(status: AuthStatus.unauthenticated);
      },
    );
  }

  /// Register new user
  Future<void> register(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.register(email, password);

    result.fold(
      onSuccess: (user) {
        // Registration successful, but user needs to login
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Registration successful! Please log in.',
        );
      },
      onFailure: (error) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _getErrorMessage(error),
        );
      },
    );
  }

  /// Login user
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(email, password);

    result.fold(
      onSuccess: (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
      onFailure: (error) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _getErrorMessage(error),
        );
      },
    );
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    final repository = ref.read(authRepositoryProvider);
    await repository.logout();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Get user-friendly error message
  String _getErrorMessage(AppException error) {
    switch (error.code) {
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password';
      case 'EMAIL_EXISTS':
        return 'An account with this email already exists';
      case 'TOKEN_EXPIRED':
        return 'Session expired. Please log in again';
      case 'TOKEN_INVALID':
        return 'Invalid session. Please log in again';
      case 'UNAUTHORIZED':
        return 'Please log in to continue';
      case 'REFRESH_FAILED':
        return 'Session expired. Please log in again';
      case 'NO_CONNECTION':
        return 'No internet connection. Please check your network';
      case 'TIMEOUT':
        return 'Request timed out. Please try again';
      case 'SERVER_UNREACHABLE':
        return 'Unable to reach server. Please try again later';
      case 'VALIDATION_ERROR':
        return error.message;
      default:
        final message = error.message.trim();
        return message.isEmpty ? 'An error occurred. Please try again' : message;
    }
  }
}

/// Provider to check if user is authenticated (for routing)
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
}

/// Provider to get current user
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
}

/// Provider to get access token
@riverpod
Future<String?> accessToken(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getAccessToken();
}

/// Auth initialization provider (runs on app start)
@riverpod
Future<void> authInitializer(Ref ref) async {
  final notifier = ref.read(authProvider.notifier);
  await notifier.initialize();
}
