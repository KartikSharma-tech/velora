import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/models/chat_tile_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _surface2 = Color(0xFF1A2332);
  static const _primary = Color(0xFF6C63FF);
  static const _primaryDark = Color(0xFF5A4FF5);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _textHint = Color(0xFF64748B);
  static const _border = Color(0xFF2D3748);
  static const _online = Color(0xFF22C55E);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go(AppRouter.login);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to logout. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: _textSecondary),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }

        final chatsAsync = ref.watch(chatTilesProvider(user.uid));

        return Scaffold(
          backgroundColor: _bg,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(
            context,
            ref,
            user.name,
            user.photoUrl,
            user.uid,
            user.isOnline,
          ),
          body: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: RefreshIndicator(
                  color: _primary,
                  backgroundColor: _surface,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            children: [
                              const Text(
                                'Messages',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Spacer(),
                              chatsAsync.maybeWhen(
                                data: (chats) => chats.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primary.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${chats.length}',
                                          style: const TextStyle(
                                            color: _primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      chatsAsync.when(
                        loading: () => const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        ),
                        error: (error, _) => SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                error.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _textSecondary),
                              ),
                            ),
                          ),
                        ),
                        data: (chats) {
                          if (chats.isEmpty) {
                            return SliverFillRemaining(
                              child: _buildEmptyState(),
                            );
                          }
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: _buildChatTile(
                                    context,
                                    ref,
                                    chats[index],
                                    user.uid,
                                  ),
                                ),
                                childCount: chats.length,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String name,
    String photoUrl,
    String userId,
    bool isOnline,
  ) {
    return AppBar(
      backgroundColor: _bg.withValues(alpha: 0.95),
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Velora',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.push(AppRouter.searchUsers),
          icon: const Icon(Icons.search_rounded, color: _textSecondary),
        ),
        // Avatar with dynamic online dot
        GestureDetector(
          onTap: () => context.push(AppRouter.profile),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primary.withValues(alpha: 0.2),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _online,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _bg.withValues(alpha: 0.95),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _textSecondary),
          color: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _border),
          ),
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
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: const [
                  Icon(
                    Icons.person_outline_rounded,
                    color: _textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Profile',
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: const [
                  Icon(
                    Icons.settings_outlined,
                    color: _textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primary.withValues(alpha: 0.12),
                  _primary.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryDark.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    WidgetRef ref,
    ChatTileModel chat,
    String userId,
  ) {
    return GestureDetector(
      onLongPress: () {
        ref
            .read(chatRepositoryProvider)
            .togglePinChat(
              roomId: chat.roomId,
              userId: userId,
              pin: !chat.isPinned,
            );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: chat.isPinned
                  ? _primary.withValues(alpha: 0.08)
                  : _surface2.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: chat.isPinned
                    ? _primary.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: _primary.withValues(alpha: 0.08),
                highlightColor: _primary.withValues(alpha: 0.04),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: _primary.withValues(alpha: 0.15),
                            backgroundImage: chat.otherUserPhoto.isNotEmpty
                                ? NetworkImage(chat.otherUserPhoto)
                                : null,
                            child: chat.otherUserPhoto.isEmpty
                                ? Text(
                                    chat.otherUserName.isEmpty
                                        ? '?'
                                        : chat.otherUserName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  )
                                : null,
                          ),
                          if (chat.otherUserOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _online,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _surface2,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    chat.otherUserName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                if (chat.isPinned) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.push_pin_rounded,
                                    size: 12,
                                    color: _primary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              chat.lastMessage.isEmpty
                                  ? 'Start chatting...'
                                  : chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: chat.lastMessageSeen
                                    ? _textHint
                                    : _textSecondary,
                                fontSize: 13,
                                fontWeight: chat.lastMessageSeen
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.chatListTime(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: chat.lastMessageSeen
                                  ? _textHint
                                  : _primary,
                              fontWeight: chat.lastMessageSeen
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (!chat.lastMessageSeen)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 9),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _primary.withValues(alpha: 0.20)),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 38,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the pencil button to start\na new conversation',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.searchUsers),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.chat_rounded, color: Colors.white),
        label: const Text(
          'New Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
