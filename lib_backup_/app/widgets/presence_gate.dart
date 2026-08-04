import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/user/presentation/providers/user_provider.dart';

/// Wraps the whole app (above [MaterialApp.router]) and keeps
/// `users/{uid}.isOnline` in sync with real app state.
///
/// BUG FIX: `setOnlineStatus()` already existed on the user
/// repository but nothing in the UI ever called it — every user's
/// presence froze at whatever `isOnline` was written during signup
/// (`true`, forever), so "Online" / "Last seen" never reflected
/// reality. This widget is the missing wiring:
///  - flips online -> true the moment a user is authenticated
///  - flips online -> false (with a fresh lastSeen) when the app is
///    backgrounded / closed
///  - flips back to true on resume
class PresenceGate extends ConsumerStatefulWidget {
  const PresenceGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PresenceGate> createState() => _PresenceGateState();
}

class _PresenceGateState extends ConsumerState<PresenceGate>
    with WidgetsBindingObserver {
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _currentUid;
    if (uid == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(uid, true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _setOnline(uid, false);
        break;
    }
  }

  void _setOnline(String uid, bool isOnline) {
    ref.read(userRepositoryProvider).setOnlineStatus(
          uid: uid,
          isOnline: isOnline,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;

      // Just logged in / app resumed with an existing session.
      if (next != null) {
        _currentUid = next;
        _setOnline(next, true);
      }

      // Just logged out — mark the *previous* user offline.
      if (next == null && previous != null) {
        _setOnline(previous, false);
        _currentUid = null;
      }
    });

    return widget.child;
  }
}
