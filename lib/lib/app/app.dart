import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_provider.dart';
// import '../core/router/app_router.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/presence_gate.dart';

class VeloraApp extends ConsumerWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return PresenceGate(
      child: MaterialApp.router(
        title: 'Velora',

        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,

        routerConfig: AppRouter.router,
      ),
    );
  }
}