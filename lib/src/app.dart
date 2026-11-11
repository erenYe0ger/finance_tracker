import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class FinanceTrackerApp extends ConsumerWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Force dark theme as per requirements
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Use Material 3 text scaling
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaler.scale(1.0)),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Initialize auth on app start - separate widget to avoid router rebuild issues
class AuthInitializer extends ConsumerWidget {
  const AuthInitializer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize auth on first build
    ref.listenManual(authInitializerProvider, (_, _) {});
    return child;
  }
}