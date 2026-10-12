import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/user/presentation/providers/user_provider.dart';

/// PresenceGate — user ke online/offline status ko track karta hai.
/// currentUserIdProvider ab StreamProvider hai, isliye ref.listen ka
/// type AsyncValue<String?> hona chahiye aur .valueOrNull se value nikalte hain.
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
    // FIX: currentUserIdProvider ab StreamProvider<String?> hai
    // Type AsyncValue<String?> hona chahiye, .valueOrNull se value nikalo
    ref.listen<AsyncValue<String?>>(
      currentUserIdProvider,
      (previous, next) {
        final prevVal = previous?.valueOrNull;
        final nextVal = next.valueOrNull;

        // Koi change nahi — early return
        if (prevVal == nextVal) return;

        // User login hua
        if (nextVal != null) {
          _currentUid = nextVal;
          _setOnline(nextVal, true);
        }

        // User logout hua
        if (nextVal == null && prevVal != null) {
          _setOnline(prevVal, false);
          _currentUid = null;
        }
      },
    );

    return widget.child;
  }
}