import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat_requests/presentation/screens/chat_requests_screen.dart';
import '../../features/contacts/presentation/screens/discover_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

@immutable
final class AppRouter {
  const AppRouter._();

  // ===========================================================
  // Route Paths
  // ===========================================================

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';

  /// Contacts-based discovery screen — replaces the old
  /// "browse every registered user" search screen. Kept at this
  /// same path/const name so nothing else in the app needs to
  /// change what it links to.
  static const String searchUsers = '/search-users';
  static const String chatRequests = '/chat-requests';

  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // ===========================================================
  // Navigation helpers
  // ===========================================================

  /// Pops one level if there's somewhere to pop *back* to;
  /// otherwise falls back to Home instead of doing nothing / letting
  /// the OS handle (and potentially exit) the app. Use this for
  /// every in-app back arrow so "back" never gets stuck on a screen
  /// with an empty stack above it.
  static void backOrHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(home);
    }
  }

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
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: searchUsers,
        name: 'discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: chatRequests,
        name: 'chat-requests',
        builder: (context, state) => const ChatRequestsScreen(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: chat,
        name: 'chat',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;

          return ChatScreen(
            roomId: args['roomId'] as String,
            receiverId: args['receiverId'] as String,
            receiverName: args['receiverName'] as String,
          );
        },
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
