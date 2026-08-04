import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/user/presentation/providers/user_provider.dart';

/// Wraps the whole app (above [MaterialApp.router]) and keeps
/// `users/{uid}.isOnline` in sync with real app state.
///
/// BUG FIX ("user remains Online even after leaving the app"):
/// this used to capture `_currentUid` *only* inside a
/// `ref.listen(currentUserIdProvider, ...)` callback. `ref.listen`
/// only fires on a *change* — it does NOT run for the value that
/// was already current the moment listening started. So for anyone
/// who re-opened the app while an existing Firebase session was
/// still valid (the normal "auto login" case, not a fresh
/// email/password login), `currentUserIdProvider` was non-null on
/// the very first build and `ref.listen` never saw a null->uid
/// transition to react to. `_currentUid` stayed permanently null,
/// so `didChangeAppLifecycleState` always bailed out early and
/// *never* flipped the user offline on background/close. Whatever
/// `isOnline` happened to already be in Firestore just stuck
/// forever. Fixed by syncing `_currentUid` from `ref.watch` on
/// every build (always current), and by eagerly marking the user
/// online the moment a session is detected — `ref.listen` is kept
/// only to react to genuine login/logout transitions mid-session.
class PresenceGate extends ConsumerStatefulWidget {
  const PresenceGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PresenceGate> createState() => _PresenceGateState();
}

class _PresenceGateState extends ConsumerState<PresenceGate>
    with WidgetsBindingObserver {
  String? _currentUid;
  bool _markedOnlineForCurrentUid = false;

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
    final uid = ref.watch(currentUserIdProvider);

    // Always kept current — this is what fixes the stuck-online bug.
    _currentUid = uid;

    if (uid == null) {
      _markedOnlineForCurrentUid = false;
    } else if (!_markedOnlineForCurrentUid) {
      // Covers both a fresh login *and* an app cold-start that
      // resumed an already-authenticated session — either way, the
      // first time we see this uid in a build, make sure Firestore
      // reflects "online" instead of trusting whatever was left
      // over from the last session.
      _markedOnlineForCurrentUid = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setOnline(uid, true);
      });
    }

    // Still listen for explicit transitions so a logout mid-session
    // immediately marks the *previous* user offline.
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      if (next == null && previous != null) {
        _setOnline(previous, false);
      }
    });

    return widget.child;
  }
}
