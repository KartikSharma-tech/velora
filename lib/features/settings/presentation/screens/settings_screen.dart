import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../core/utils/phone_normalizer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // FIX: StreamProvider hai to .valueOrNull use karo
    final userId = ref.watch(currentUserIdProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (mode) =>
                ref.read(themeModeProvider.notifier).set(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (mode) =>
                ref.read(themeModeProvider.notifier).set(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (mode) =>
                ref.read(themeModeProvider.notifier).set(mode!),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Privacy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (userId != null) const _VerifiedPhoneSetting(),
          if (userId != null) _BlockedUsersList(userId: userId),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _VerifiedPhoneSetting extends ConsumerStatefulWidget {
  const _VerifiedPhoneSetting();

  @override
  ConsumerState<_VerifiedPhoneSetting> createState() =>
      _VerifiedPhoneSettingState();
}

class _VerifiedPhoneSettingState extends ConsumerState<_VerifiedPhoneSetting> {
  bool _busy = false;
  String? _verifiedPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

  Future<void> _linkPhone() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    await authUser.reload();
    if (!FirebaseAuth.instance.currentUser!.emailVerified) {
      _showMessage('Verify your email before linking a phone number.');
      return;
    }

    setState(() => _busy = true);
    try {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        final stored = await ref
            .read(authRepositoryProvider)
            .verifyAndLinkPhoneNumber(null);
        if (mounted) setState(() => _verifiedPhone = stored);
        _showMessage('Verified phone number synced to your profile.');
        return;
      }

      if (kIsWeb) {
        _showMessage('Open Velora on your phone to verify a number.');
        return;
      }

      final phoneToVerify = await _requestPhoneNumber();
      if (phoneToVerify == null || !mounted) return;
      final credential = await _requestPhoneCredential(phoneToVerify);
      if (credential == null || !mounted) return;

      final stored = await ref
          .read(authRepositoryProvider)
          .verifyAndLinkPhoneNumber(credential);
      if (mounted) setState(() => _verifiedPhone = stored);
      _showMessage('Phone number verified and linked.');
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Phone verification failed.');
    } catch (_) {
      _showMessage('Phone verification failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _requestPhoneNumber() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Verify phone number'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '98765 43210',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = PhoneNormalizer.normalize(
                  controller.text.trim(),
                );
                if (normalized == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid phone number.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, normalized);
              },
              child: const Text('Send code'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<PhoneAuthCredential?> _requestPhoneCredential(String phone) async {
    final verification = Completer<PhoneAuthCredential?>();
    String? verificationId;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) {
        if (!verification.isCompleted) verification.complete(credential);
      },
      verificationFailed: (error) {
        if (!verification.isCompleted) verification.completeError(error);
      },
      codeSent: (id, _) {
        verificationId = id;
        if (!verification.isCompleted) verification.complete(null);
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
        if (!verification.isCompleted) verification.complete(null);
      },
      timeout: const Duration(seconds: 60),
    );

    final automaticCredential = await verification.future;
    if (automaticCredential != null) return automaticCredential;
    final id = verificationId;
    if (id == null || !mounted) return null;

    final codeController = TextEditingController();
    try {
      final code = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enter verification code'),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'SMS code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final code = codeController.text.trim();
                if (code.length != 6) return;
                Navigator.pop(dialogContext, code);
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      );
      if (code == null) return null;
      return PhoneAuthProvider.credential(verificationId: id, smsCode: code);
    } finally {
      codeController.dispose();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.verified_user_outlined),
      title: const Text('Verified phone'),
      subtitle: Text(
        _verifiedPhone ??
            (kIsWeb
                ? 'Verify in the mobile app to enable contact matching'
                : 'Required for secure contact matching'),
      ),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _linkPhone,
              child: Text(_verifiedPhone == null ? 'Verify' : 'Sync'),
            ),
    );
  }
}

class _BlockedUsersList extends ConsumerWidget {
  const _BlockedUsersList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserAsync = ref.watch(currentUserProvider(userId));

    return myUserAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (me) {
        final blocked = me?.blockedUsers ?? const [];

        if (blocked.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'No blocked users',
              style: TextStyle(color: AppColors.textHint),
            ),
          );
        }

        final allUsersAsync = ref.watch(allUsersProvider);

        return allUsersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (allUsers) {
            final blockedUsers = allUsers
                .where((u) => blocked.contains(u.uid))
                .toList();

            return Column(
              children: blockedUsers.map((user) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.avatarBackground,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name[0].toUpperCase(),
                          )
                        : null,
                  ),
                  title: Text(user.name),
                  trailing: TextButton(
                    onPressed: () {
                      ref
                          .read(userRepositoryProvider)
                          .unblockUser(uid: userId, blockedUid: user.uid);
                    },
                    child: const Text('Unblock'),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
