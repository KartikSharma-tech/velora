import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_users_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/chat_requests/presentation/screens/chat_requests_screen.dart';
import 'package:go_router/go_router.dart';

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
  static const String searchUsers = '/search-users';
  static const String chat = '/chat';
    static const chatRequests = '/chat-requests';
static void backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRouter.home);
  }
}
  static const String profile = '/profile';
  static const String settings = '/settings';

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
        name: 'search-users',
        builder: (context, state) => const SearchUsersScreen(),
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
      GoRoute(
  path: AppRouter.chatRequests,
  builder: (context, state) => const ChatRequestsScreen(),
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