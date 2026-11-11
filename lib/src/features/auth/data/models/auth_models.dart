import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// User model matching backend SafeUser schema
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String email,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Token pair from login/refresh
@freezed
abstract class TokenPair with _$TokenPair {
  const factory TokenPair({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type') @Default('bearer') String tokenType,
    @JsonKey(name: 'expires_in') required int expiresIn,
  }) = _TokenPair;

  factory TokenPair.fromJson(Map<String, dynamic> json) => _$TokenPairFromJson(json);
}

/// Credentials for login/register
@freezed
abstract class Credentials with _$Credentials {
  const factory Credentials({
    required String email,
    required String password,
  }) = _Credentials;

  factory Credentials.fromJson(Map<String, dynamic> json) => _$CredentialsFromJson(json);
}

/// Register request
@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
}

/// Login request
@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

/// Refresh request
@freezed
abstract class RefreshRequest with _$RefreshRequest {
  const factory RefreshRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshRequest;

  factory RefreshRequest.fromJson(Map<String, dynamic> json) => _$RefreshRequestFromJson(json);
}

/// Logout request
@freezed
abstract class LogoutRequest with _$LogoutRequest {
  const factory LogoutRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) => _$LogoutRequestFromJson(json);
}

/// Safe user response (from /me endpoint)
@freezed
abstract class SafeUser with _$SafeUser {
  const factory SafeUser({
    required int id,
    required String email,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _SafeUser;

  factory SafeUser.fromJson(Map<String, dynamic> json) => _$SafeUserFromJson(json);
}

/// Logout response
@freezed
abstract class LogoutResponse with _$LogoutResponse {
  const factory LogoutResponse({
    required String detail,
  }) = _LogoutResponse;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) => _$LogoutResponseFromJson(json);
}

/// Health check response
@freezed
abstract class HealthResponse with _$HealthResponse {
  const factory HealthResponse({
    required String status,
    required String service,
  }) = _HealthResponse;

  factory HealthResponse.fromJson(Map<String, dynamic> json) => _$HealthResponseFromJson(json);
}

/// Database health response
@freezed
abstract class DatabaseHealthResponse with _$DatabaseHealthResponse {
  const factory DatabaseHealthResponse({
    required String status,
    required String database,
  }) = _DatabaseHealthResponse;

  factory DatabaseHealthResponse.fromJson(Map<String, dynamic> json) => _$DatabaseHealthResponseFromJson(json);
}