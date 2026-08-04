import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../shared/enums/privacy_enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      await ref.read(userRepositoryProvider).setOnlineStatus(
            uid: uid,
            isOnline: false,
          );
    }
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => AppRouter.backOrHome(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode!),
          ),
          const Divider(height: 32),
          if (userId != null) _PrivacySettings(userId: userId),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Blocked Users', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (userId != null) _BlockedUsersList(userId: userId),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _PrivacySettings extends ConsumerWidget {
  const _PrivacySettings({required this.userId});

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
        if (me == null) return const SizedBox.shrink();

        Future<void> updateWhoCanMessage(WhoCanMessage value) {
          return ref.read(userRepositoryProvider).updatePrivacySettings(
                uid: userId,
                whoCanMessage: value,
                discoverability: me.discoverability,
              );
        }

        Future<void> updateDiscoverability(Discoverability value) {
          return ref.read(userRepositoryProvider).updatePrivacySettings(
                uid: userId,
                whoCanMessage: me.whoCanMessage,
                discoverability: value,
              );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Who can message me',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ...WhoCanMessage.values.map(
              (option) => RadioListTile<WhoCanMessage>(
                dense: true,
                title: Text(option.label),
                subtitle: Text(
                  option.description,
                  style: const TextStyle(fontSize: 12),
                ),
                value: option,
                groupValue: me.whoCanMessage,
                onChanged: (value) => updateWhoCanMessage(value!),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Who can find me',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ...Discoverability.values.map(
              (option) => RadioListTile<Discoverability>(
                dense: true,
                title: Text(option.label),
                subtitle: Text(
                  option.description,
                  style: const TextStyle(fontSize: 12),
                ),
                value: option,
                groupValue: me.discoverability,
                onChanged: (value) => updateDiscoverability(value!),
              ),
            ),
            if (me.phoneNumber.isEmpty &&
                me.discoverability == Discoverability.phoneNumber)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  "Add a phone number in Profile so contacts can actually find you.",
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            if (me.username.isEmpty && me.discoverability == Discoverability.username)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  "Set a username in Profile so people can search for you.",
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        );
      },
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
            child: Text('No blocked users', style: TextStyle(color: AppColors.textHint)),
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
            final blockedUsers =
                allUsers.where((u) => blocked.contains(u.uid)).toList();

            return Column(
              children: blockedUsers.map((user) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.avatarBackground,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user.name),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(userRepositoryProvider).unblockUser(
                            uid: userId,
                            blockedUid: user.uid,
                          );
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
