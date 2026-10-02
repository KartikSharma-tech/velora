import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/domain/services/messaging_permission.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/services/messaging_permission_resolver.dart';
import '../../../chat_requests/presentation/providers/chat_request_provider.dart';
import '../../../user/data/models/user_model.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/velora_contact.dart';
import '../providers/contacts_provider.dart';
import '../widgets/send_request_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final granted = await ref
        .read(contactRepositoryProvider)
        .requestPermission();

    if (granted) {
      ref.invalidate(contactSyncProvider(true));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Contacts permission denied. You can still find people by username, "
            "or enable it later from your phone's app settings.",
          ),
        ),
      );
    }
  }

  Future<void> _openUser(UserModel target) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    setState(() => _busy = true);

    final permission = await MessagingPermissionResolver.resolve(
      ref: ref,
      currentUserId: currentUserId,
      target: target,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    switch (permission) {
      case MessagingPermission.allowed:
        final roomId = await ref
            .read(chatRepositoryProvider)
            .createChatRoom(participants: [currentUserId, target.uid]);
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
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => SendRequestSheet(target: target),
        );
        break;

      case MessagingPermission.blocked:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${target.name} isn't accepting new messages right now.",
            ),
          ),
        );
        break;
    }
  }

  // Future<void> _openVeloraContact(VeloraContact contact) async {
  //   if (contact.uid == null) return;

  //   final userAsync = ref.read(currentUserProvider(contact.uid!));
  //   final user = await userAsync.future;
  //   if (user == null || !mounted) return;

  //   await _openUser(user);
  // }
  Future<void> _openVeloraContact(VeloraContact contact) async {
    if (contact.uid == null) return;

    // final user = ref.read(currentUserProvider(contact.uid!)).value;
      final user = await ref.read(currentUserProvider(contact.uid!).future);

    if (user == null || !mounted) return;

    await _openUser(user);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final incomingRequestsAsync = ref.watch(
      incomingChatRequestsProvider(currentUserId),
    );
    final incomingCount = incomingRequestsAsync.maybeWhen(
      data: (requests) => requests.length,
      orElse: () => 0,
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
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
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Chat requests',
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  onPressed: () => context.push(AppRouter.chatRequests),
                ),
                if (incomingCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$incomingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by username...',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ),
                Expanded(
                  child: _query.isNotEmpty
                      ? _UsernameResults(query: _query, onTap: _openUser)
                      : _ContactsList(
                          onRequestPermission: _requestPermission,
                          onTap: _openVeloraContact,
                        ),
                ),
              ],
            ),
            if (_busy)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Username Search ──────────────────────────────────────────────────
class _UsernameResults extends ConsumerWidget {
  const _UsernameResults({required this.query, required this.onTap});

  final String query;
  final ValueChanged<UserModel> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(usernameSearchProvider(query));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
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
              subtitle: Text('@${user.username}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onTap(user),
            );
          },
        );
      },
    );
  }
}

// ── Contacts List ────────────────────────────────────────────────────
class _ContactsList extends ConsumerWidget {
  const _ContactsList({required this.onRequestPermission, required this.onTap});

  final VoidCallback onRequestPermission;
  final ValueChanged<VeloraContact> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermissionAsync = ref.watch(hasContactsPermissionProvider);

    return hasPermissionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error.toString(), textAlign: TextAlign.center),
        ),
      ),
      data: (hasPermission) {
        if (!hasPermission) {
          return _PermissionBanner(onRequestPermission: onRequestPermission);
        }

        final syncAsync = ref.watch(contactSyncProvider(false));

        return syncAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error.toString(), textAlign: TextAlign.center),
            ),
          ),
          data: (result) {
            final onVelora = result.onVelora;
            final notOnVelora = result.notOnVelora;

            if (onVelora.isEmpty && notOnVelora.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: 56,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "None of your contacts are on Velora yet",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Search by username above to find someone directly.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(contactSyncProvider(true)),
              child: CustomScrollView(
                slivers: [
                  // On Velora section
                  if (onVelora.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'ON VELORA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final contact = onVelora[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.avatarBackground,
                            backgroundImage:
                                contact.photoUrl?.isNotEmpty == true
                                ? NetworkImage(contact.photoUrl!)
                                : null,
                            child: contact.photoUrl?.isNotEmpty != true
                                ? Text(
                                    contact.displayName.isEmpty
                                        ? '?'
                                        : contact.displayName[0].toUpperCase(),
                                  )
                                : null,
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(
                            contact.veloraName != null &&
                                    contact.veloraName != contact.displayName
                                ? 'Velora: ${contact.veloraName}'
                                : 'On Velora',
                          ),
                          trailing: const Icon(
                            Icons.chat_bubble_outline_rounded,
                          ),
                          onTap: () => onTap(contact),
                        );
                      }, childCount: onVelora.length),
                    ),
                  ],

                  // Invite section
                  if (notOnVelora.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'INVITE TO VELORA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final contact = notOnVelora[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.avatarBackground,
                            child: Text(
                              contact.displayName.isEmpty
                                  ? '?'
                                  : contact.displayName[0].toUpperCase(),
                            ),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(contact.phone),
                          trailing: TextButton(
                            onPressed: () async {
                              await SharePlus.instance.share(
                                ShareParams(
                                  text:
                                      'Hey! Join me on Velora — a fast, private chat app.\n\nDownload it here:\nhttps://play.google.com/store/apps/details?id=com.velora.app',
                                  subject: 'Join me on Velora!',
                                ),
                              );
                            },
                            child: const Text('Invite'),
                          ),
                        );
                      }, childCount: notOnVelora.length),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Permission Banner ────────────────────────────────────────────────
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onRequestPermission});

  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Find people you know',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Velora can check your contacts against registered users so you "
              "only see people you actually know — nobody else. Your contacts "
              "are never uploaded or stored.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRequestPermission,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Allow Contacts Access'),
            ),
          ],
        ),
      ),
    );
  }
}
