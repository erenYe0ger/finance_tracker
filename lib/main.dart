import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with ProviderScope
  runApp(
    const ProviderScope(
      child: AuthInitializer(child: FinanceTrackerApp()),
    ),
  );
}