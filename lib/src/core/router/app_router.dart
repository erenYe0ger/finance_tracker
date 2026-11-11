import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return _buildRouter(ref);
});

GoRouter _buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      return _redirectLogic(authState, state);
    },
    routes: _buildRoutes(),
    errorBuilder: (context, state) => _buildErrorPage(context, state),
  );
}

String? _redirectLogic(AuthState authState, GoRouterState state) {
  final isLoggedIn = authState.isAuthenticated;
  final isLoggingIn = state.matchedLocation == LoginScreen.routePath;
  final isRegistering = state.matchedLocation == RegisterScreen.routePath;
  final isPublicRoute = isLoggingIn || isRegistering;

  if (!isLoggedIn && !isPublicRoute) {
    return LoginScreen.routePath;
  }
  if (isLoggedIn && isPublicRoute) {
    return '/';
  }
  return null;
}

List<GoRoute> _buildRoutes() {
  return [
    // Auth routes (public)
    GoRoute(
      path: LoginScreen.routePath,
      name: LoginScreen.routeName,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RegisterScreen.routePath,
      name: RegisterScreen.routeName,
      builder: (context, state) => const RegisterScreen(),
    ),

    // Protected routes
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        // Future: transactions, budgets, etc.
      ],
    ),
  ];
}

Widget _buildErrorPage(BuildContext context, GoRouterState state) {
  final theme = Theme.of(context);
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.toString() ?? 'Unknown error',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}