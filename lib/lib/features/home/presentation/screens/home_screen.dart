import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/models/chat_tile_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// BUG FIX (back navigation): Home is the *root* of the
  /// navigation stack — Splash/Login reach it via `context.go()`,
  /// which intentionally clears the stack so users can't go
  /// "back" into the auth flow. That's correct GoRouter usage, but
  /// it also means Home has nothing left to pop, so a hardware/
  /// gesture back press here used to fall straight through to the
  /// OS and kill the app instantly — no confirmation, felt like a
  /// crash. This adds the standard "press back again to exit"
  /// pattern instead of an abrupt close. Search Users and Chat
  /// aren't touched — they're pushed with `context.push()` and
  /// already pop correctly one level at a time.
  DateTime? _lastBackPress;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      final uid = ref.read(currentUserIdProvider);
      if (uid != null) {
        await ref.read(userRepositoryProvider).setOnlineStatus(
              uid: uid,
              isOnline: false,
            );
      }

      await ref.read(authRepositoryProvider).signOut();

      if (context.mounted) {
        context.go(AppRouter.login);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to logout. Please try again.')),
        );
      }
    }
  }

  void _handleBackPress() {
    final now = DateTime.now();

    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chatsAsync = ref.watch(chatTilesProvider(userId));
    final currentUserAsync = ref.watch(currentUserProvider(userId));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Velora',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              context.push(AppRouter.searchUsers);
            },
            icon: const Icon(Icons.search_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  context.push(AppRouter.profile);
                  break;

                case 'settings':
                  context.push(AppRouter.settings);
                  break;

                case 'logout':
                  await _logout(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome Back 👋"),
                        const SizedBox(height: 4),
                        currentUserAsync.when(
                          data: (user) => Text(
                            user?.name ?? userId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          loading: () => const Text(
                            "Loading...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          error: (_, _) => Text(
                            userId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.online,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text("Online"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Recent Chats",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            chatsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(error.toString(), textAlign: TextAlign.center),
                ),
              ),

              data: (chats) {
                if (chats.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No conversations yet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tap the + button below to start chatting with someone.",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chats.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ChatTileModel chat = chats[index];

                    return ListTile(
                      tileColor: chat.isPinned
                          ? AppColors.primary.withValues(alpha: .06)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        context.push(
                          AppRouter.chat,
                          extra: {
                            'roomId': chat.roomId,
                            'receiverId': chat.otherUserId,
                            'receiverName': chat.otherUserName,
                          },
                        );
                      },
                      onLongPress: () {
                        ref.read(chatRepositoryProvider).togglePinChat(
                              roomId: chat.roomId,
                              userId: userId,
                              pin: !chat.isPinned,
                            );
                      },
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.avatarBackground,
                            backgroundImage: chat.otherUserPhoto.isNotEmpty
                                ? NetworkImage(chat.otherUserPhoto)
                                : null,
                            child: chat.otherUserPhoto.isEmpty
                                ? Text(
                                    chat.otherUserName.isEmpty
                                        ? "?"
                                        : chat.otherUserName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          if (chat.otherUserOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.online,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              chat.otherUserName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (chat.isPinned) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: AppColors.textHint,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        chat.lastMessage.isEmpty
                            ? "Start chatting..."
                            : chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.chatListTime(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: chat.lastMessageSeen
                                  ? AppColors.textHint
                                  : AppColors.primary,
                              fontWeight: chat.lastMessageSeen
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (!chat.lastMessageSeen)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRouter.searchUsers);
        },
        icon: const Icon(Icons.chat_rounded),
        label: const Text("New Chat"),
      ),
      ),
    );
  }
}
