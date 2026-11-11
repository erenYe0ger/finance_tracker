/// User entity (domain layer)
class User {
  final int id;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  /// Create from remote model
  factory User.fromRemote(dynamic remote) {
    // Handle different remote types
    if (remote is Map<String, dynamic>) {
      return User(
        id: remote['id'] as int,
        email: remote['email'] as String,
        createdAt: DateTime.parse(remote['created_at'] as String),
      );
    }
    throw ArgumentError('Invalid remote user type: ${remote.runtimeType}');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id && email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, createdAt: $createdAt)';
}

/// Auth state enum
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

/// Auth state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? accessToken,
    String? refreshToken,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  String toString() => 'AuthState(status: $status, user: $user, hasTokens: ${accessToken != null})';
}