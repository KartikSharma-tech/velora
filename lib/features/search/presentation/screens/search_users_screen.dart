import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/domain/services/messaging_permission.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/services/messaging_permission_resolver.dart';
import '../../../contacts/presentation/widgets/send_request_sheet.dart';
import '../../../user/data/models/user_model.dart';
import '../../../user/presentation/providers/user_provider.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openUser(UserModel currentUser, UserModel target) async {
    try {
      final permission = await MessagingPermissionResolver.resolve(
        ref: ref,
        currentUserId: currentUser.uid,
        target: target,
      );
      if (!mounted) return;

      switch (permission) {
        case MessagingPermission.allowed:
          final roomId = await ref
              .read(chatRepositoryProvider)
              .createChatRoom(participants: [currentUser.uid, target.uid]);
          if (!mounted) return;
          context.push(
            AppRouter.chat,
            extra: {
              'roomId': roomId,
              'receiverId': target.uid,
              'receiverName': target.name,
            },
          );
          break;
        case MessagingPermission.requestRequired:
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => SendRequestSheet(target: target),
          );
          break;
        case MessagingPermission.blocked:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${target.name} isn't accepting new messages."),
            ),
          );
          break;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this conversation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // PERMANENT FIX: appUserProvider
    final userAsync = ref.watch(appUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final usersAsync = ref.watch(allUsersProvider);

        return Scaffold(
          appBar: AppBar(title: const Text('New Chat')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: usersAsync.when(
                  data: (users) {
                    final filtered = users.where((user) {
                      if (user.uid == currentUser.uid) return false;
                      return user.name.toLowerCase().contains(_query) ||
                          user.email.toLowerCase().contains(_query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name[0].toUpperCase(),
                            ),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble),
                            onPressed: () => _openUser(currentUser, user),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text(error.toString())),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
