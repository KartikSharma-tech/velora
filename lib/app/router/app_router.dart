import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';

@immutable
final class AppRouter {
  const AppRouter._();

  // ===========================================================
  // Route Names
  // ===========================================================

  static const String splash = '/';

  // ===========================================================
  // Router
  // ===========================================================

  static final GoRouter router = GoRouter(
    initialLocation: splash,

    debugLogDiagnostics: true,

    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text(
            state.error?.toString() ?? 'Page Not Found',
          ),
        ),
      );
    },
  );
}