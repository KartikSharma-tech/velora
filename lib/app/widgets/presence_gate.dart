import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/user/presentation/providers/user_provider.dart';
import '../../../features/user/data/models/user_model.dart';

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
    if (_currentUid == null) return;
    if (state == AppLifecycleState.resumed) {
      _setOnline(_currentUid!, true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnline(_currentUid!, false);
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
    // ── NEW: seed _currentUid on first build if user already logged in ──
    final currentUser = ref.watch(appUserProvider).valueOrNull;
    if (currentUser != null && _currentUid == null) {
      _currentUid = currentUser.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setOnline(currentUser.uid, true);
      });
    }

    // ── EXISTING: react to login / logout / user-switch ──
    ref.listen<AsyncValue<UserModel?>>(
      appUserProvider,
      (previous, next) {
        final prevUser = previous?.valueOrNull;
        final nextUser = next.valueOrNull;

        if (prevUser?.uid == nextUser?.uid) return;

        if (nextUser != null) {
          _currentUid = nextUser.uid;
          _setOnline(nextUser.uid, true);
        }

        if (nextUser == null && prevUser != null) {
          _setOnline(prevUser.uid, false);
          _currentUid = null;
        }
      },
    );

    return widget.child;
  }
}