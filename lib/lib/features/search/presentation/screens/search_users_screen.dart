import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() =>
      _SearchUsersScreenState();
}

class _SearchUsersScreenState
    extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return PopScope(
      canPop: context.canPop(),
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go(AppRouter.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Chat'),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppRouter.backOrHome(context),
          ),
        ),
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
                  if (user.uid == currentUserId) {
                    return false;
                  }

                  return user.name
                          .toLowerCase()
                          .contains(_query) ||
                      user.email
                          .toLowerCase()
                          .contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
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
                        onPressed: () async {
                          if (currentUserId == null) return;

                          final roomId = await ref
                              .read(chatRepositoryProvider)
                              .createChatRoom(
                                participants: [
                                  currentUserId,
                                  user.uid,
                                ],
                              );

                          if (!context.mounted) return;

                          context.push(
                            AppRouter.chat,
                            extra: {
                              'roomId': roomId,
                              'receiverId': user.uid,
                              'receiverName': user.name,
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text(error.toString()),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}