import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // authStateChanges wait — Firebase auth genuinely ready hone tak
    final user = await FirebaseAuth.instance.authStateChanges().first;

    if (!mounted) return;

    if (user == null) {
      context.go(AppRouter.login);
      return;
    }

    // reload + force token refresh
    try {
      await user.reload();
      await user.getIdToken(true);
    } catch (_) {}

    if (!mounted) return;

    final freshUser = FirebaseAuth.instance.currentUser;

    if (freshUser == null || !freshUser.emailVerified) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go(AppRouter.login);
      return;
    }

    // Extra wait — Firestore SDK ko token propagate karne ka waqt do
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "app_logo",
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .25),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                ),

                AppSpacing.gapXXXL,

                Text(
                  "Velora",
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                AppSpacing.gapSM,

                Text(
                  "Luxury Messaging Experience",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 55),

                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}