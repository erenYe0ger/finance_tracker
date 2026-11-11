import '../entities/user.dart' as domain;
import '../../../../core/errors/app_exceptions.dart';

/// Abstract repository for auth operations
abstract class AuthRepository {
  /// Register a new user
  Future<Result<domain.User>> register(String email, String password);

  /// Login user
  Future<Result<domain.User>> login(String email, String password);

  /// Refresh access token
  Future<Result<AuthTokens>> refreshToken();

  /// Logout user
  Future<Result<void>> logout();

  /// Get current user profile
  Future<Result<domain.User>> getCurrentUser();

  /// Check if user is logged in (has valid tokens)
  Future<bool> isLoggedIn();

  /// Get stored access token
  Future<String?> getAccessToken();

  /// Get stored refresh token
  Future<String?> getRefreshToken();

  /// Clear all auth data
  Future<void> clearAuth();
}
/// Token data class
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}